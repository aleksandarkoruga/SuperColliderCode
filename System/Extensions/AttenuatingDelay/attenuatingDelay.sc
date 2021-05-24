// without mul and add.
AttenuatingDelay : UGen {
    *ar { arg in = 0.0, distance = 0.3, power=3.0;
        ^this.multiNew('audio', in, distance, power);
    }
}