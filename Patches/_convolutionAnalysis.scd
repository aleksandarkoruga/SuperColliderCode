
Degree of cross correlation, x(t)Xv(t)= conj(FFT(x))*FFT(v), with slight modifications on the range of the output. Being the output of identical signals ->inf and not correlated 0, i transformed them using the dbamp function to convert from logarithmic to linear range. Well enough the value of a random signal against a sinusoid has an average of 0.5, a completely identical signal 1 ,and a decorrelated signal an oscillating value between 0 and 1 based on the distance in frequency between the two sinusoids.


 ({

	var chain1, chain2, chain3,chain3conj1,chain3conj2,chain4;
	var sig1, sig2;

	sig1=SinOsc.ar; //+220.0*SinOsc.ar(440*Lag.ar(WhiteNoise.ar.abs,0.5)));
	sig2= SinOsc.ar((220.0+ (990.0*Linen.kr(1,30.0,1.0,1.0))).poll(label:"freq"));//SinOsc.ar();

	//for cross correlation
	chain1=FFT(LocalBuf(2048), sig1);
	chain2=FFT(LocalBuf(2048), sig2);

	//for deconvolution
	chain3=PV_Copy(chain1,LocalBuf(2048));
	chain4=PV_Copy(chain2,LocalBuf(2048));

	chain3conj1=PV_Conj(PV_Copy(chain1,LocalBuf(2048)));
	chain3conj2=PV_Conj(PV_Copy(chain1,LocalBuf(2048)));



	//deconvolution with Tikhonov  regularization   http://www.ce.memphis.edu/7137/PDFs/signal%20Processing/deconv.pdf
	chain3conj1= PV_Mul(chain3conj1,chain4);
	chain3conj2=PV_Add(PV_Mul(chain3conj2,chain3) , 	FFT(LocalBuf(2048), WhiteNoise.ar.abs*0.001) );
	chain3conj1=PV_Div(chain3conj1,chain3conj2);


	Out.ar(0,IFFT(chain3conj1).scope.poll(label:"deconvolution"));


	//cross-correlation
	chain1= PV_Conj(chain1);
	chain2= PV_Mul(chain1,chain2);
	(1.0-(Amplitude.ar(IFFT(chain2),10.1,10.1) *(-1.0)).dbamp).scope.poll(label:"cross-correlation");
	//IFFT(chain2).scope;



}.play)

