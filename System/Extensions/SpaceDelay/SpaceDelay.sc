// without mul and add.
SpaceDelay : UGen {
    *ar { arg in = 0.0, delay = 0.3, maxdelay = 0.3, fb = 0.9, coeff = 0.95;
        ^this.multiNew('audio', in, delay, maxdelay, fb, coeff);
    }
	*kr { arg in = 0.0, delay = 0.3, maxdelay = 0.3, fb = 0.9, coeff = 0.95;
        ^this.multiNew('control', in, delay, maxdelay, fb, coeff);
    }

}