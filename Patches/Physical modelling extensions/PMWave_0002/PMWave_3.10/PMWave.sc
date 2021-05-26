PMWave : PureUGen  {
	*ar { arg in = 0.0, damping=0.5, pitch=0.9,speed=0.01 ,cutoff=0.0005,pAmt1=0.0,pAmt2=0.0, probTrig=0.0, mul = 1.0, add = 0.0;
		^this.multiNew('audio', in, damping, pitch,speed ,cutoff,pAmt1,pAmt2, probTrig ).madd(mul, add)
	}
	*kr { arg in = 0.0, damping=0.99, pitch=0.9,speed=0.01 ,cutoff=0.0005,pAmt1=0.0,pAmt2=0.0, probTrig=0.0, mul = 1.0, add = 0.0;
		^this.multiNew('control',in, damping, pitch,speed,cutoff,pAmt1,pAmt2, probTrig).madd(mul, add)
	}
}