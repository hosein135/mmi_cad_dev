# Import Image as Layout
# File / Local menu: "Import Image as Layout..."
#
# Learned from MIP (Max Image Paster) and xchiplogo:
#   an image is thresholded to ink, then each ink pixel is painted
#   with db_paint. MIP shelled out to ImageMagick and a C program,
#   wrote a temp .mag, and issued one rectangle per black pixel.
#
# This version runs inside MAX (Tcl 8.0):
#   - reads PBM, PGM, PPM, and GIF itself
#   - uses ImageMagick only for PNG, JPEG, and other formats
#   - keeps thin dark lines when the picture is reduced
#   - optional smooth and minimum-width grow (the xchiplogo idea)
#   - merges horizontal runs into rectangles before painting
#   - paints upright, with the bottom of the picture on the origin
#
# Tcl 8.0 limits: no dict, no {*}, no lset, no string map / string is,
# no \s \d regexp classes, no file normalize.

global _IMG2LAY_REV_LOADED IMG2LAY
set _IMG2LAY_REV 1
if {[info exists _IMG2LAY_REV_LOADED]} {
  if {$_IMG2LAY_REV_LOADED >= $_IMG2LAY_REV} { return }
}
set _IMG2LAY_REV_LOADED $_IMG2LAY_REV

if {![info exists IMG2LAY(file)]} { set IMG2LAY(file) "" }
if {![info exists IMG2LAY(layer)]} { set IMG2LAY(layer) "" }
if {![info exists IMG2LAY(threshold)]} { set IMG2LAY(threshold) 128 }
if {![info exists IMG2LAY(invert)]} { set IMG2LAY(invert) 0 }
if {![info exists IMG2LAY(maxdim)]} { set IMG2LAY(maxdim) 480 }
if {![info exists IMG2LAY(smooth)]} { set IMG2LAY(smooth) 0 }
if {![info exists IMG2LAY(smooth_at)]} { set IMG2LAY(smooth_at) 8 }
if {![info exists IMG2LAY(minw)]} { set IMG2LAY(minw) 1 }
if {![info exists IMG2LAY(scale)]} { set IMG2LAY(scale) 1 }
if {![info exists IMG2LAY(place)]} { set IMG2LAY(place) "Cell origin (0, 0)" }
if {![info exists IMG2LAY(busy)]} { set IMG2LAY(busy) 0 }
if {![info exists IMG2LAY(cancel)]} { set IMG2LAY(cancel) 0 }

proc img2lay_int {val} {
  set n 0
  if {[scan $val %f n] != 1} {
    error "expected a number, got '$val'"
  }
  return [expr {int($n)}]
}

proc img2lay_have {cmd} {
  if {[info commands auto_execok] == ""} { return 0 }
  if {[auto_execok $cmd] == ""} { return 0 }
  return 1
}

proc img2lay_tmpdir {} {
  global env
  foreach d {/tmp /var/tmp} {
    if {[file isdirectory $d] && [file writable $d]} { return $d }
  }
  if {[info exists env(TMP)]} {
    if {[file isdirectory $env(TMP)] && [file writable $env(TMP)]} {
      return $env(TMP)
    }
  }
  if {[info exists env(TEMP)]} {
    if {[file isdirectory $env(TEMP)] && [file writable $env(TEMP)]} {
      return $env(TEMP)
    }
  }
  return [pwd]
}

proc img2lay_u8 {data i} {
  set v 0
  if {[binary scan $data "@${i}c" v] != 1} {
    error "image file ended early"
  }
  if {$v < 0} { set v [expr {$v + 256}] }
  return $v
}

proc img2lay_token {data iVar} {
  upvar $iVar i
  set n [string length $data]
  while {$i < $n} {
    set c [string index $data $i]
    if {$c == " " || $c == "\n" || $c == "\r" || $c == "\t" || $c == "\f"} {
      incr i
      continue
    }
    if {$c == "#"} {
      while {$i < $n && [string index $data $i] != "\n"} { incr i }
      continue
    }
    break
  }
  if {$i >= $n} { return "" }
  set start $i
  while {$i < $n} {
    set c [string index $data $i]
    if {$c == " " || $c == "\n" || $c == "\r" || $c == "\t" || $c == "\f" || $c == "#"} {
      break
    }
    incr i
  }
  return [string range $data $start [expr {$i - 1}]]
}

proc img2lay_skip_one_ws {data iVar} {
  upvar $iVar i
  set n [string length $data]
  if {$i >= $n} { error "image file ended early" }
  set c [string index $data $i]
  if {$c == " " || $c == "\t" || $c == "\n" || $c == "\r" || $c == "\f"} {
    incr i
    if {$c == "\r" && $i < $n && [string index $data $i] == "\n"} {
      incr i
    }
  }
}

proc img2lay_step {w h maxdim} {
  if {$maxdim < 1} { set maxdim 1 }
  set m $w
  if {$h > $m} { set m $h }
  if {$m <= $maxdim} { return 1 }
  set step [expr {$m / $maxdim}]
  if {$step < 1} { set step 1 }
  if {$w > $maxdim * $step || $h > $maxdim * $step} {
    incr step
  }
  return $step
}

proc img2lay_check_size {w h} {
  if {$w < 1 || $h < 1} { error "image has no pixels" }
  if {$w > 8000 || $h > 8000} {
    error "Image is ${w}x${h}. The longest side must be 8000 pixels or less."
  }
  if {[expr {$w * $h}] > 1500000} {
    error "Image is ${w}x${h}, which is too large to trace directly.\nUse PNG or JPEG (ImageMagick resizes those) or a smaller bitmap."
  }
}

# Block is ink when any pixel in it is dark (or, if inverted, any pixel is light).
# That keeps one-pixel lines that a plain average would erase.
proc img2lay_build_mask {w h step threshold invert} {
  global IMG2LAY
  img2lay_check_size $w $h
  set ow [expr {($w + $step - 1) / $step}]
  set oh [expr {($h + $step - 1) / $step}]
  set rows {}
  for {set oy 0} {$oy < $oh} {incr oy} {
    if {[info exists IMG2LAY(cancel)] && $IMG2LAY(cancel)} {
      error "Cancelled."
    }
    set y0 [expr {$oy * $step}]
    set y1 [expr {$y0 + $step}]
    if {$y1 > $h} { set y1 $h }
    set chars {}
    for {set ox 0} {$ox < $ow} {incr ox} {
      set x0 [expr {$ox * $step}]
      set x1 [expr {$x0 + $step}]
      if {$x1 > $w} { set x1 $w }
      set dark 0
      set light 0
      for {set y $y0} {$y < $y1 && !($dark && $light)} {incr y} {
        for {set x $x0} {$x < $x1} {incr x} {
          set lum [img2lay_lum_at $x $y]
          if {$lum <= $threshold} { set dark 1 } else { set light 1 }
          if {$dark && $light} { break }
        }
      }
      if {$invert} {
        if {$light} { lappend chars 1 } else { lappend chars 0 }
      } else {
        if {$dark} { lappend chars 1 } else { lappend chars 0 }
      }
    }
    lappend rows [join $chars ""]
    if {$oy % 24 == 0} {
      img2lay_progress "Reading image ($oy / $oh)"
      update
    }
  }
  return [list $ow $oh $rows]
}

proc img2lay_lum_at {x y} {
  global IMG2LAY_RASTER
  set kind $IMG2LAY_RASTER(kind)
  if {$kind == "p5"} {
    set i [expr {$IMG2LAY_RASTER(off) + $y * $IMG2LAY_RASTER(w) + $x}]
    set v [img2lay_u8 $IMG2LAY_RASTER(data) $i]
    return [expr {$v * 255 / $IMG2LAY_RASTER(maxval)}]
  }
  if {$kind == "p6"} {
    set i [expr {$IMG2LAY_RASTER(off) + ($y * $IMG2LAY_RASTER(w) + $x) * 3}]
    set r [img2lay_u8 $IMG2LAY_RASTER(data) $i]
    set g [img2lay_u8 $IMG2LAY_RASTER(data) [expr {$i + 1}]]
    set b [img2lay_u8 $IMG2LAY_RASTER(data) [expr {$i + 2}]]
    return [expr {($r * 299 + $g * 587 + $b * 114) / 1000}]
  }
  if {$kind == "p4"} {
    set w $IMG2LAY_RASTER(w)
    set nbytes [expr {($w + 7) / 8}]
    set i [expr {$IMG2LAY_RASTER(off) + $y * $nbytes + $x / 8}]
    set v [img2lay_u8 $IMG2LAY_RASTER(data) $i]
    set shift [expr {7 - ($x % 8)}]
    set bit [expr {($v >> $shift) & 1}]
    if {$bit} { return 0 }
    return 255
  }
  if {$kind == "ascii"} {
    set i [expr {$y * $IMG2LAY_RASTER(w) + $x}]
    return [img2lay_u8 $IMG2LAY_RASTER(lums) $i]
  }
  if {$kind == "photo"} {
    set rgb [$IMG2LAY_RASTER(photo) get $x $y]
    if {[llength $rgb] < 3} { error "could not read a pixel from the image" }
    set r [lindex $rgb 0]
    set g [lindex $rgb 1]
    set b [lindex $rgb 2]
    return [expr {($r * 299 + $g * 587 + $b * 114) / 1000}]
  }
  error "internal: bad raster kind '$kind'"
}

proc img2lay_need_int {tok} {
  set num 0
  if {[scan $tok %d num] != 1} { error "bad image sample '$tok'" }
  return $num
}

proc img2lay_load_netpbm {data threshold invert maxdim} {
  global IMG2LAY_RASTER
  set i 0
  set magic [img2lay_token $data i]
  if {$magic != "P1" && $magic != "P2" && $magic != "P3" && \
      $magic != "P4" && $magic != "P5" && $magic != "P6"} {
    error "not a PBM, PGM, or PPM image"
  }
  set w [img2lay_need_int [img2lay_token $data i]]
  set h [img2lay_need_int [img2lay_token $data i]]
  if {$w < 1 || $h < 1} { error "image has no pixels" }
  set maxval 1
  if {$magic != "P1" && $magic != "P4"} {
    set maxval [img2lay_need_int [img2lay_token $data i]]
    if {$maxval < 1} { error "image maxval is invalid" }
  }
  set ascii 0
  if {$magic == "P1" || $magic == "P2" || $magic == "P3"} { set ascii 1 }
  if {!$ascii && $maxval > 255 && $magic != "P4"} {
    error "binary PGM/PPM maxval $maxval is unsupported. Re-save with maxval 255."
  }
  if {$ascii && [expr {$w * $h}] > 800000} {
    error "ASCII image is ${w}x${h}. Save it as binary PGM (P5) or as PNG."
  }

  catch {unset IMG2LAY_RASTER}
  set IMG2LAY_RASTER(w) $w
  set IMG2LAY_RASTER(h) $h
  set IMG2LAY_RASTER(maxval) $maxval

  if {$ascii} {
    set need [expr {$w * $h}]
    if {$magic == "P3"} { set need [expr {$need * 3}] }
    set vals {}
    for {set n 0} {$n < $need} {incr n} {
      set tok [img2lay_token $data i]
      if {$tok == ""} { error "image file ended early" }
      lappend vals [img2lay_need_int $tok]
    }
    set lums {}
    if {$magic == "P1"} {
      foreach num $vals {
        if {$num != 0} { lappend lums 0 } else { lappend lums 255 }
      }
    } elseif {$magic == "P2"} {
      foreach num $vals {
        lappend lums [expr {$num * 255 / $maxval}]
      }
    } else {
      set n [llength $vals]
      for {set k 0} {$k < $n} {incr k 3} {
        set r [lindex $vals $k]
        set g [lindex $vals [expr {$k + 1}]]
        set b [lindex $vals [expr {$k + 2}]]
        lappend lums [expr {($r * 299 + $g * 587 + $b * 114) / 1000 * 255 / $maxval}]
      }
    }
    set IMG2LAY_RASTER(kind) ascii
    set IMG2LAY_RASTER(lums) [binary format c* $lums]
  } else {
    img2lay_skip_one_ws $data i
    set IMG2LAY_RASTER(off) $i
    set IMG2LAY_RASTER(data) $data
    if {$magic == "P4"} {
      set IMG2LAY_RASTER(kind) p4
    } elseif {$magic == "P5"} {
      set IMG2LAY_RASTER(kind) p5
    } else {
      set IMG2LAY_RASTER(kind) p6
    }
  }

  set step [img2lay_step $w $h $maxdim]
  set rc [catch {set mask [img2lay_build_mask $w $h $step $threshold $invert]} err]
  catch {unset IMG2LAY_RASTER}
  if {$rc} { error $err }
  return $mask
}

proc img2lay_load_photo {path threshold invert maxdim} {
  global IMG2LAY_RASTER
  set ph img2lay_photo
  catch {image delete $ph}
  set err ""
  if {[catch {image create photo $ph -file $path} err]} {
    error $err
  }
  set w [image width $ph]
  set h [image height $ph]
  catch {unset IMG2LAY_RASTER}
  set IMG2LAY_RASTER(kind) photo
  set IMG2LAY_RASTER(photo) $ph
  set IMG2LAY_RASTER(w) $w
  set step [img2lay_step $w $h $maxdim]
  set rc [catch {set mask [img2lay_build_mask $w $h $step $threshold $invert]} err]
  catch {image delete $ph}
  catch {unset IMG2LAY_RASTER}
  if {$rc} { error $err }
  return $mask
}

proc img2lay_convert {src dest maxdim} {
  set geom "${maxdim}x${maxdim}>"
  set errors ""
  set ran 0
  if {[img2lay_have convert]} {
    set ran 1
    file delete -force $dest
    if {![catch {exec convert $src -background white -alpha remove -flatten -resize $geom -compress none $dest} err]} {
      if {[file exists $dest] && [file size $dest] > 0} { return }
    }
    append errors "convert: $err\n"
  }
  if {[img2lay_have magick]} {
    set ran 1
    file delete -force $dest
    if {![catch {exec magick $src -background white -alpha remove -flatten -resize $geom -compress none $dest} err]} {
      if {[file exists $dest] && [file size $dest] > 0} { return }
    }
    append errors "magick: $err\n"
  }
  if {[img2lay_have gm]} {
    set ran 1
    file delete -force $dest
    if {![catch {exec gm convert $src -resize $geom $dest} err]} {
      if {[file exists $dest] && [file size $dest] > 0} { return }
    }
    append errors "gm: $err\n"
  }
  file delete -force $dest
  if {!$ran} {
    error "PNG, JPEG, and BMP need ImageMagick (convert or magick) on PATH.\nPBM, PGM, PPM, and GIF are read directly."
  }
  error "Image conversion failed.\n$errors"
}

proc img2lay_readbin {path} {
  if {![file exists $path]} { error "file not found:\n$path" }
  set fh [open $path r]
  fconfigure $fh -translation binary
  set data [read $fh]
  close $fh
  return $data
}

proc img2lay_sniff {data} {
  set m2 [string range $data 0 1]
  if {$m2 == "P1" || $m2 == "P2" || $m2 == "P3" || \
      $m2 == "P4" || $m2 == "P5" || $m2 == "P6"} {
    return netpbm
  }
  if {[string length $data] >= 4 && [string range $data 0 3] == "GIF8"} {
    return gif
  }
  if {[string length $data] >= 1} {
    set b0 [img2lay_u8 $data 0]
    if {$b0 == 137 || $b0 == 255} { return raster }
  }
  if {$m2 == "BM"} { return raster }
  return other
}

proc img2lay_load_path {path threshold invert maxdim} {
  set data [img2lay_readbin $path]
  if {[string length $data] < 2} { error "image file is empty" }
  set kind [img2lay_sniff $data]
  if {$kind == "netpbm"} {
    return [img2lay_load_netpbm $data $threshold $invert $maxdim]
  }

  set photo_err ""
  set convert_err ""
  if {$kind == "gif" || $kind == "other"} {
    if {[info commands image] != ""} {
      if {![catch {set mask [img2lay_load_photo $path $threshold $invert $maxdim]} photo_err]} {
        return $mask
      }
    }
  }

  set tmp [file join [img2lay_tmpdir] "img2lay_[pid].pgm"]
  set rc [catch {img2lay_convert $path $tmp $maxdim} convert_err]
  if {$rc} {
    if {$kind == "raster" && [info commands image] != ""} {
      if {![catch {set mask [img2lay_load_photo $path $threshold $invert $maxdim]} photo_err]} {
        return $mask
      }
    }
    if {$photo_err != ""} {
      error "Could not read the image.\n$photo_err\n$convert_err"
    }
    error $convert_err
  }
  set rc [catch {set data [img2lay_readbin $tmp]} err]
  file delete -force $tmp
  if {$rc} { error $err }
  return [img2lay_load_netpbm $data $threshold $invert $maxdim]
}

proc img2lay_smooth {rows radius strict} {
  set h [llength $rows]
  if {$h == 0} { return $rows }
  set w [string length [lindex $rows 0]]
  if {$strict < 1} { set strict 1 }
  if {$strict > 16} { set strict 16 }
  set out {}
  for {set y 0} {$y < $h} {incr y} {
    set chars {}
    for {set x 0} {$x < $w} {incr x} {
      set cnt 0
      set n 0
      for {set dy [expr {-$radius}]} {$dy <= $radius} {incr dy} {
        set yy [expr {$y + $dy}]
        if {$yy < 0 || $yy >= $h} { continue }
        set row [lindex $rows $yy]
        for {set dx [expr {-$radius}]} {$dx <= $radius} {incr dx} {
          set xx [expr {$x + $dx}]
          if {$xx < 0 || $xx >= $w} { continue }
          incr n
          if {[string index $row $xx] == "1"} { incr cnt }
        }
      }
      if {$n < 1} { set n 1 }
      if {[expr {$cnt * 16 > $n * $strict}]} {
        lappend chars 1
      } else {
        lappend chars 0
      }
    }
    lappend out [join $chars ""]
  }
  return $out
}

proc img2lay_span {a0 a1 minw bound} {
  set extra [expr {$minw - ($a1 - $a0)}]
  if {$extra <= 0} { return [list $a0 $a1] }
  set left [expr {$extra / 2}]
  set right [expr {$extra - $left}]
  set a [expr {$a0 - $left}]
  set b [expr {$a1 + $right}]
  if {$a < 0} {
    set b [expr {$b - $a}]
    set a 0
  }
  if {$b > $bound} {
    set a [expr {$a - ($b - $bound)}]
    set b $bound
  }
  if {$a < 0} { set a 0 }
  if {$b > $bound} { set b $bound }
  return [list $a $b]
}

proc img2lay_grow_h {rows minw} {
  set out {}
  foreach row $rows {
    set w [string length $row]
    set runs {}
    set x 0
    while {$x < $w} {
      if {[string index $row $x] != "1"} {
        incr x
        continue
      }
      set x0 $x
      while {$x < $w && [string index $row $x] == "1"} { incr x }
      lappend runs [list $x0 $x]
    }
    foreach run $runs {
      set x0 [lindex $run 0]
      set x1 [lindex $run 1]
      if {[expr {$x1 - $x0}] >= $minw} { continue }
      set span [img2lay_span $x0 $x1 $minw $w]
      set a [lindex $span 0]
      set b [lindex $span 1]
      for {set i $a} {$i < $b} {incr i} {
        set row [string replace $row $i $i 1]
      }
    }
    lappend out $row
  }
  return $out
}

proc img2lay_grow_v {rows minw} {
  set h [llength $rows]
  if {$h == 0} { return $rows }
  set w [string length [lindex $rows 0]]
  for {set x 0} {$x < $w} {incr x} {
    set runs {}
    set y 0
    while {$y < $h} {
      if {[string index [lindex $rows $y] $x] != "1"} {
        incr y
        continue
      }
      set y0 $y
      while {$y < $h && [string index [lindex $rows $y] $x] == "1"} { incr y }
      lappend runs [list $y0 $y]
    }
    foreach run $runs {
      set y0 [lindex $run 0]
      set y1 [lindex $run 1]
      if {[expr {$y1 - $y0}] >= $minw} { continue }
      set span [img2lay_span $y0 $y1 $minw $h]
      set a [lindex $span 0]
      set b [lindex $span 1]
      for {set i $a} {$i < $b} {incr i} {
        set row [lindex $rows $i]
        set row [string replace $row $x $x 1]
        set rows [lreplace $rows $i $i $row]
      }
    }
  }
  return $rows
}

proc img2lay_grow {rows minw} {
  if {$minw <= 1} { return $rows }
  return [img2lay_grow_v [img2lay_grow_h $rows $minw] $minw]
}

proc img2lay_runs {row} {
  set runs {}
  set w [string length $row]
  set x 0
  while {$x < $w} {
    if {[string index $row $x] != "1"} {
      incr x
      continue
    }
    set x0 $x
    while {$x < $w && [string index $row $x] == "1"} { incr x }
    lappend runs [list $x0 $x]
  }
  return $runs
}

# Rectangles are x0 y0 x1 y1 in image space (y down, x1/y1 exclusive).
proc img2lay_rects {rows} {
  set rects {}
  set active {}
  set y 0
  foreach row $rows {
    set runs [img2lay_runs $row]
    set next {}
    foreach a $active {
      set ax0 [lindex $a 0]
      set ax1 [lindex $a 1]
      set ay [lindex $a 2]
      set kept 0
      set remain {}
      foreach r $runs {
        if {!$kept && [lindex $r 0] == $ax0 && [lindex $r 1] == $ax1} {
          set kept 1
          lappend next [list $ax0 $ax1 $ay]
        } else {
          lappend remain $r
        }
      }
      set runs $remain
      if {!$kept} {
        lappend rects [list $ax0 $ay $ax1 $y]
      }
    }
    foreach r $runs {
      lappend next [list [lindex $r 0] [lindex $r 1] $y]
    }
    set active $next
    incr y
  }
  foreach a $active {
    lappend rects [list [lindex $a 0] [lindex $a 2] [lindex $a 1] $y]
  }
  return $rects
}

proc img2lay_db_box {x0 y0 x1 y1 h scale ox oy} {
  set dbx0 [expr {$ox + $x0 * $scale}]
  set dbx1 [expr {$ox + $x1 * $scale}]
  set dby0 [expr {$oy + ($h - $y1) * $scale}]
  set dby1 [expr {$oy + ($h - $y0) * $scale}]
  return [list $dbx0 $dby0 $dbx1 $dby1]
}

proc img2lay_db_rects {rows scale ox oy} {
  set h [llength $rows]
  set out {}
  foreach r [img2lay_rects $rows] {
    lappend out [img2lay_db_box [lindex $r 0] [lindex $r 1] \
        [lindex $r 2] [lindex $r 3] $h $scale $ox $oy]
  }
  return $out
}

proc img2lay_trace {rows smooth strict minw} {
  if {$smooth} {
    img2lay_progress "Smoothing..."
    update
    set rows [img2lay_smooth $rows 1 $strict]
  }
  if {$minw > 1} {
    img2lay_progress "Growing narrow features to $minw pixels..."
    update
    set rows [img2lay_grow $rows $minw]
  }
  return $rows
}

proc img2lay_layers {} {
  set skip {annotation background bbox box drc feedback flyline grid label selection subcell}
  set out {}
  if {[info commands dbt_layers] != ""} {
    foreach L [dbt_layers] {
      set bad 0
      foreach s $skip {
        if {$L == $s} { set bad 1 }
      }
      if {!$bad} { lappend out $L }
    }
  }
  if {[llength $out] == 0} {
    set out {poly m1 m2 m3 ndif pdif}
  }
  return $out
}

proc img2lay_pick_layer {layers} {
  foreach want {poly m1 metal1 li} {
    foreach L $layers {
      if {$L == $want} { return $L }
    }
  }
  return [lindex $layers 0]
}

proc img2lay_tell {msg} {
  if {[info commands tk_messageBox] != ""} {
    tk_messageBox -title "Import Image as Layout" -message $msg -type ok
  } else {
    puts $msg
  }
}

proc img2lay_progress_open {} {
  catch {destroy .img2lay_prog}
  toplevel .img2lay_prog
  wm title .img2lay_prog "Import Image as Layout"
  wm geometry .img2lay_prog +80+80
  set f .img2lay_prog.f
  frame $f -bd 10
  pack $f
  label $f.msg -text "Starting..." -width 54 -anchor w
  pack $f.msg -fill x
  button $f.stop -text "Cancel" -command {set IMG2LAY(cancel) 1}
  pack $f.stop -pady 6
  update idletasks
}

proc img2lay_progress_close {} {
  catch {destroy .img2lay_prog}
}

proc img2lay_progress {text} {
  if {![winfo exists .img2lay_prog.f.msg]} { return }
  .img2lay_prog.f.msg configure -text $text
  update idletasks
}

proc img2lay_zoom {x0 y0 x1 y1} {
  if {[info commands lay_box] != ""} {
    catch {lay_box $x0 $y0 $x1 $y1}
  }
  if {[info commands :findbox] != ""} {
    catch {:findbox zoom}
  } elseif {[info commands view_center] != ""} {
    catch {view_center [expr {($x0 + $x1) / 2}] [expr {($y0 + $y1) / 2}]}
  }
}

proc img2lay_go {} {
  global IMG2LAY
  set path [string trim $IMG2LAY(file)]
  if {$path == ""} { error "Choose an image file." }
  if {![file exists $path]} { error "file not found:\n$path" }

  set layers [img2lay_layers]
  set layer [string trim $IMG2LAY(layer)]
  if {$layer == ""} { set layer [img2lay_pick_layer $layers] }
  set known 0
  foreach L $layers {
    if {$L == $layer} { set known 1 }
  }
  if {!$known} { error "Layer '$layer' is not in this technology." }

  if {[info commands lay_editcell] != ""} {
    if {[lay_editcell] == ""} {
      error "No edit cell is open. Use File → New or File → Open first."
    }
  }
  if {[info commands db_cell_read_only] != ""} {
    if {[db_cell_read_only]} { error "The edit cell is read-only." }
  }
  if {[info commands db_paint] == ""} {
    error "db_paint is not available. Run this from MAX."
  }

  set threshold [img2lay_int $IMG2LAY(threshold)]
  if {$threshold < 0} { set threshold 0 }
  if {$threshold > 255} { set threshold 255 }
  set maxdim [img2lay_int $IMG2LAY(maxdim)]
  if {$maxdim < 8} { set maxdim 8 }
  if {$maxdim > 1024} { set maxdim 1024 }
  set strict [img2lay_int $IMG2LAY(smooth_at)]
  set minw [img2lay_int $IMG2LAY(minw)]
  if {$minw < 1} { set minw 1 }
  if {$minw > 64} { set minw 64 }
  set scale [img2lay_int $IMG2LAY(scale)]
  set invert 0
  if {$IMG2LAY(invert)} { set invert 1 }
  set smooth 0
  if {$IMG2LAY(smooth)} { set smooth 1 }

  set ox 0
  set oy 0
  set boxw 0
  set boxh 0
  set place $IMG2LAY(place)
  if {$place != "Fit inside the box" && $scale < 1} {
    error "Scale must be at least 1 database unit per pixel."
  }
  if {$place == "Box lower-left" || $place == "Fit inside the box"} {
    if {[info commands lay_box] == ""} { error "The box tool is not available." }
    set box [lay_box]
    if {[llength $box] != 4} {
      error "Draw a box first (hotkey b), then place the image on that box."
    }
    set ox [img2lay_int [lindex $box 0]]
    set oy [img2lay_int [lindex $box 1]]
    set x1 [img2lay_int [lindex $box 2]]
    set y1 [img2lay_int [lindex $box 3]]
    if {$x1 < $ox} {
      set t $ox
      set ox $x1
      set x1 $t
    }
    if {$y1 < $oy} {
      set t $oy
      set oy $y1
      set y1 $t
    }
    set boxw [expr {$x1 - $ox}]
    set boxh [expr {$y1 - $oy}]
    if {$place == "Fit inside the box" && ($boxw < 1 || $boxh < 1)} {
      error "The box is empty."
    }
  }

  img2lay_progress_open
  img2lay_progress "Reading [file tail $path]..."
  update
  set mask [img2lay_load_path $path $threshold $invert $maxdim]
  set ow [lindex $mask 0]
  set oh [lindex $mask 1]
  set rows [lindex $mask 2]
  set rows [img2lay_trace $rows $smooth $strict $minw]

  if {$place == "Fit inside the box"} {
    set sx [expr {$boxw / $ow}]
    set sy [expr {$boxh / $oh}]
    set scale $sx
    if {$sy < $scale} { set scale $sy }
    if {$scale < 1} { set scale 1 }
  }

  img2lay_progress "Merging rectangles..."
  update
  set dbrects [img2lay_db_rects $rows $scale $ox $oy]
  set nrect [llength $dbrects]
  if {$nrect == 0} {
    img2lay_progress_close
    img2lay_tell "No ink was found in [file tail $path].\n\nLower the threshold to keep more grays, or turn on Invert for a light drawing on a dark background."
    return
  }
  if {$nrect > 120000} {
    error "This image becomes $nrect rectangles.\nLower Max edge, or turn on Smooth, so the layout stays editable."
  }

  set done 0
  foreach box $dbrects {
    if {$IMG2LAY(cancel)} { break }
    db_paint $layer [lindex $box 0] [lindex $box 1] [lindex $box 2] [lindex $box 3]
    incr done
    if {$done % 40 == 0} {
      img2lay_progress "Painting $done / $nrect on $layer"
      update
    }
  }
  set x0 $ox
  set y0 $oy
  set x1 [expr {$ox + $ow * $scale}]
  set y1 [expr {$oy + $oh * $scale}]
  img2lay_zoom $x0 $y0 $x1 $y1
  img2lay_progress_close

  if {$IMG2LAY(cancel)} {
    img2lay_tell "Stopped early.\nPainted $done of $nrect rectangles on $layer.\nUndo removes them."
    return
  }
  img2lay_tell "Pasted $done rectangles on layer $layer.\n\nImage ${ow}x${oh} pixels, $scale database units per pixel.\nThe box outlines the artwork.\nUndo removes the whole paste."
}

proc img2lay_dialog {} {
  global IMG2LAY
  if {$IMG2LAY(busy)} {
    img2lay_tell "An image import is already running."
    return
  }
  set layers [img2lay_layers]
  set layer_ok 0
  foreach L $layers {
    if {$L == $IMG2LAY(layer)} { set layer_ok 1 }
  }
  if {!$layer_ok} {
    set IMG2LAY(layer) [img2lay_pick_layer $layers]
  }
  set prop_list ""
  lappend prop_list [list "Image file:" IMG2LAY(file) \
      -filename [list -message {Image to trace} \
          -pattern [list *.png *.jpg *.jpeg *.gif *.pbm *.pgm *.ppm *.pnm *.bmp]] \
      -width 56 \
      -help {PBM, PGM, PPM, and GIF are read in MAX. PNG, JPEG, and BMP are resized with ImageMagick when convert or magick is on PATH.}]
  lappend prop_list [list "Layer:" IMG2LAY(layer) -popup $layers -width 18 \
      -help {Paint goes on this technology layer in the current edit cell.}]
  lappend prop_list [list "Darker than (0-255):" IMG2LAY(threshold) \
      -scale 0 255 -incr 1 \
      -help {Pixels this dark or darker become ink. 0 keeps only pure black. 255 keeps every pixel.}]
  lappend prop_list [list "Invert (paint the light pixels):" IMG2LAY(invert) -binary \
      -help {Use this for a white logo on a black background.}]
  lappend prop_list [list "Max edge (pixels):" IMG2LAY(maxdim) -number {8 1024} \
      -help {Longest side after reduction. Lower this if the paste is too detailed. Thin dark lines are kept.}]
  lappend prop_list [list "Smooth speckles:" IMG2LAY(smooth) -binary \
      -help {Neighborhood vote, the same idea as xchiplogo smoothing. Off leaves the thresholded picture alone.}]
  lappend prop_list [list "Smooth strictness (4 keeps more, 16 keeps less):" \
      IMG2LAY(smooth_at) -number {4 16} \
      -help {Used only when Smooth speckles is on.}]
  lappend prop_list [list "Minimum feature (pixels, 1 = off):" IMG2LAY(minw) \
      -number {1 64} \
      -help {Grow ink runs that are thinner than this, in X and then in Y.}]
  lappend prop_list [list "Database units per pixel:" IMG2LAY(scale) -number {1 10000} \
      -help {Ignored when placement is Fit inside the box. 1 matches the image 1:1 in database units.}]
  lappend prop_list [list "Placement:" IMG2LAY(place) \
      -choice [list "Cell origin (0, 0)" "Box lower-left" "Fit inside the box"] \
      -help {Fit scales the picture into the current box (hotkey b). The other two use Database units per pixel.}]

  if {![prop_menu2 -title "Import Image as Layout" $prop_list]} {
    return
  }
  set IMG2LAY(busy) 1
  set IMG2LAY(cancel) 0
  set rc [catch {img2lay_go} err]
  set IMG2LAY(busy) 0
  set IMG2LAY(cancel) 0
  if {$rc} {
    img2lay_progress_close
    if {$err == "Cancelled."} {
      img2lay_tell "Import cancelled."
    } else {
      img2lay_tell "Image import failed:\n$err"
    }
  }
}

proc img2lay_install_menus {} {
  if {[info commands menu_local_cmd] == ""} { return }
  catch {
    menu_local_cmd "Import Image as Layout..." img2lay_dialog \
        "Trace a bitmap into merged rectangles on one layer"
  }
  if {![catch {_menu_get_widget File}]} {
    catch {
      menu_add_cmd [_menu_get_widget File] "Import Image as Layout..." \
          img2lay_dialog \
          -desc "Trace a bitmap into merged rectangles on one layer"
    }
  }
}

img2lay_install_menus

proc img2lay_expect {name got want} {
  if {$got != $want} {
    error "img2lay $name:\n got  $got\n want $want"
  }
}

proc img2lay_rows_s {mask} {
  return [join [lindex $mask 2] |]
}

proc img2lay_selftest {} {
  img2lay_expect "step-small" [img2lay_step 100 80 512] 1
  img2lay_expect "step-640" [img2lay_step 640 480 512] 2
  img2lay_expect "step-exact" [img2lay_step 512 100 256] 2

  set rows [list 00110 00110 00000 10001]
  img2lay_expect "rects" [img2lay_rects $rows] [list {2 0 4 2} {0 3 1 4} {4 3 5 4}]

  set plus [list 010 111 010]
  img2lay_expect "plus" [img2lay_rects $plus] [list {1 0 2 1} {0 1 3 2} {1 2 2 3}]

  set solid [list 11 11]
  img2lay_expect "solid-db" [img2lay_db_rects $solid 1 0 0] [list {0 0 2 2}]

  set top [list 1 0]
  img2lay_expect "top-db" [img2lay_db_rects $top 2 10 20] [list {10 22 12 24}]

  set speck [list 000 010 000]
  set smoothed [img2lay_smooth $speck 1 8]
  img2lay_expect "smooth-speck" [join $smoothed |] "000|000|000"
  set block [list 111 111 111]
  set kept [img2lay_smooth $block 1 8]
  img2lay_expect "smooth-solid" [join $kept |] "111|111|111"

  set grown [img2lay_grow [list 01000] 3]
  img2lay_expect "grow-h" [lindex $grown 0] 11100

  set raw "P4\n10 1\n"
  append raw [binary format cc 240 192]
  set mask [img2lay_load_netpbm $raw 128 0 64]
  img2lay_expect "p4-row" [img2lay_rows_s $mask] 1111000011
  img2lay_expect "p4-w" [lindex $mask 0] 10

  set raw "P5\n# comment\n2 1\n255\n"
  append raw [binary format cc 10 200]
  img2lay_expect "p5" [img2lay_rows_s [img2lay_load_netpbm $raw 128 0 64]] 10
  img2lay_expect "p5-inv" [img2lay_rows_s [img2lay_load_netpbm $raw 128 1 64]] 01
  img2lay_expect "p5-all" [img2lay_rows_s [img2lay_load_netpbm $raw 255 0 64]] 11

  set raw "P6\n2 1\n255\n"
  append raw [binary format c6 {0 0 0 255 255 255}]
  img2lay_expect "p6" [img2lay_rows_s [img2lay_load_netpbm $raw 128 0 64]] 10

  set raw "P1\n# hi\n4 2\n1 1 1 1\n1 1 1 1\n"
  set mask [img2lay_load_netpbm $raw 128 0 2]
  img2lay_expect "p1-down" [img2lay_rows_s $mask] 11
  img2lay_expect "p1-h" [lindex $mask 1] 1

  set raw "P1\n4 1\n0 1 0 1\n"
  img2lay_expect "p1-or" [img2lay_rows_s [img2lay_load_netpbm $raw 128 0 2]] 11

  set raw "P3\n2 1\n255\n0 0 0  255 0 0\n"
  img2lay_expect "p3-50" [img2lay_rows_s [img2lay_load_netpbm $raw 50 0 32]] 10
  img2lay_expect "p3-128" [img2lay_rows_s [img2lay_load_netpbm $raw 128 0 32]] 11

  set rc [catch {img2lay_load_netpbm "not an image\n" 128 0 32} err]
  if {!$rc} { error "expected netpbm rejection" }

  set dir [img2lay_tmpdir]
  set path [file join $dir img2lay_selftest.ppm]
  set fh [open $path w]
  fconfigure $fh -translation binary
  puts -nonewline $fh "P6\n1 1\n255\n"
  puts -nonewline $fh [binary format c3 {0 0 0}]
  close $fh
  set mask [img2lay_load_path $path 128 0 32]
  file delete -force $path
  img2lay_expect "path" [img2lay_rows_s $mask] 1

  if {[info commands image] != ""} {
    set path [file join $dir img2lay_selftest_photo.ppm]
    set fh [open $path w]
    fconfigure $fh -translation binary
    puts -nonewline $fh "P6\n2 1\n255\n"
    puts -nonewline $fh [binary format c6 {255 255 255 0 0 0}]
    close $fh
    set mask [img2lay_load_photo $path 128 0 32]
    file delete -force $path
    img2lay_expect "photo" [img2lay_rows_s $mask] 01
  }

  puts "img2lay_selftest ok"
  return ok
}
