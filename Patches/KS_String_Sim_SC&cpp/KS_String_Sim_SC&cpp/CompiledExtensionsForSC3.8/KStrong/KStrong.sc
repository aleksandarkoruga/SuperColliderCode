// without mul and add.
KStrong : UGen {
    *ar { arg in = 0.0, del = 3.4234, fb=0.9;
        ^this.multiNew('audio', in, del, fb);
    }
}