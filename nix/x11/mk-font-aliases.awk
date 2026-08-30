# After mkfontdir: alias iso8859-1 / classic names onto whatever XLFD
# actually exists (often iso10646-1 in current Xorg bitmap packages).
BEGIN {
  n = 0
}
NR == 1 { next }
{
  xlfd = $2
  for (i = 3; i <= NF; i++) xlfd = xlfd " " $i
  if (xlfd == "") next
  n++
  f[n] = xlfd
}
END {
  for (i = 1; i <= n; i++) {
    xlfd = f[i]
    if (xlfd ~ /-iso10646-1$/) {
      iso = xlfd
      sub(/-iso10646-1$/, "-iso8859-1", iso)
      print iso, xlfd
    }
  }
  emit("fixed", "-misc-fixed-medium-r-semicondensed--13-", "-misc-fixed-medium-r-normal--13-", "-misc-fixed-medium-r-normal--14-")
  emit("9x15", "-misc-fixed-medium-r-normal--15-", "-misc-fixed-medium-r-normal--14-")
  emit("-misc-fixed-medium-r-normal--14-140-75-75-c-70-iso8859-1", "-misc-fixed-medium-r-normal--14-")
  emit("-adobe-helvetica-medium-r-normal--12-120-75-75-p-67-iso8859-1", "-adobe-helvetica-medium-r-normal--12-", "-misc-fixed-medium-r-normal--12-")
  emit("-adobe-helvetica-medium-r-normal--14-140-75-75-p-78-iso8859-1", "-adobe-helvetica-medium-r-normal--14-", "-misc-fixed-medium-r-normal--14-")
}
function emit(alias, a, b, c,    i, xlfd) {
  xlfd = pick(a)
  if (xlfd == "" && b != "") xlfd = pick(b)
  if (xlfd == "" && c != "") xlfd = pick(c)
  if (xlfd == "" && n >= 1) xlfd = f[1]
  if (xlfd != "" && xlfd != alias)
    print alias, xlfd
}
function pick(pfx,    i) {
  if (pfx == "") return ""
  for (i = 1; i <= n; i++)
    if (index(f[i], pfx) == 1) return f[i]
  return ""
}
