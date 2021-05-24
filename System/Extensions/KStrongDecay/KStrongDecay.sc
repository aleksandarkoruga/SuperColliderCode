// without mul and add.
KStrongDecay : UGen {
    *ar { arg in = 0.0, del = 3.4234, ro=0.9, s=0.5;
        ^this.multiNew('audio', in, del, ro, s);
    }
	*kr { arg in = 0.0, del = 3.4234, ro=0.9, s=0.5;
		^this.multiNew('control', in, del, ro, s);
	}
}