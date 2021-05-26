PMWave : PureUGen  {
	*ar { arg in = 0.0, damping=0.5, distance=0.5,speed=0.2 ,cutoff=0.5,pAmt1=0.0,pAmt2=0.0, probTrig=0.0, nJunctionsX = 3.0, nJunctionsY = 3.0, delaySamples = 100, mul = 1.0, add = 0.0;
		^this.multiNew('audio', in, damping, distance,speed ,cutoff,pAmt1,pAmt2, probTrig, nJunctionsX , nJunctionsY , delaySamples ).madd(mul, add)
	}
	*kr { arg in = 0.0, damping=0.5, distance=0.5,speed=0.2 ,cutoff=0.5,pAmt1=0.0,pAmt2=0.0, probTrig=0.0, nJunctionsX = 3.0, nJunctionsY = 3.0, delaySamples = 100, mul = 1.0, add = 0.0;
		^this.multiNew('control',in, damping, distance,speed ,cutoff,pAmt1,pAmt2, probTrig, nJunctionsX , nJunctionsY , delaySamples).madd(mul, add)
	}
}