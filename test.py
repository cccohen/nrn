from neuron import h

h("""create soma""")
h.load_file("stdrun.hoc")
h.soma.L = 5.6419
h.soma.diam = 5.6419
h.soma.insert("hh")
ic = h.IClamp(h.soma(0.5))
ic.delay = 0.5
ic.dur = 0.1
ic.amp = 0.3

v = h.Vector()
v.record(h.soma(0.5)._ref_v, sec=h.soma)
tv = h.Vector()
tv.record(h._ref_t, sec=h.soma)
h.run()
print(tv.to_python())
