import tkinter
r = tkinter.Tk()
r.withdraw()
p = "C:/Users/Administrator/Desktop/code/mmi_cad_dev/pdk/image_layout.tcl"
r.tk.eval("source {%s}" % p)
r.tk.eval("set mask [img2lay_load_path {C:/Users/Administrator/Desktop/code/mip/arrow.pbm} 128 0 160]")
w = r.tk.eval("lindex $mask 0")
h = r.tk.eval("lindex $mask 1")
r.tk.eval("set rows [lindex $mask 2]")
r.tk.eval("set rects [img2lay_rects $rows]")
n = r.tk.eval("llength $rects")
print("size", w, h, "rects", n)
r.destroy()
