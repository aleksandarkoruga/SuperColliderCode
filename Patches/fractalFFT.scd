

(SynthDef(\mndS,{
	|fb=4.0,pow=2.0,amt=5000.0,r=1.05|

	var tB= LocalBuf(2);
	var k=Complex.new(0.95,-0.01052);


	var inR,inC;
	var out;
	var mag;
	var c;



	inR=Duty.ar(SampleDur.ir,0,Dbufrd(tB));
	inC=Duty.ar(SampleDur.ir,0,Dbufrd(tB,1));

	c=Complex.new(inR,inC);



	k.real=((c.magnitude).poll<r.sqrt)*k.real+((c.magnitude>r.sqrt)*(100.0*WhiteNoise.ar()));

	k.imag=(c.magnitude<r.sqrt)*k.imag+((c.magnitude>r.sqrt)*(10.0*WhiteNoise.ar()));




	c= (c.pow(pow)+k);

	//c=Complex.new(c.real.fold2(2.0),c.imag.fold2(2.0));


	mag=c.magnitude;
	c.real=  c.real*(mag<r.sqrt);
	c.imag=  c.imag*(mag<r.sqrt);

	//c.real.poll;
	//c.imag.poll;
	mag=c;
	c.real=(((((mag.real-inR)+(mag.imag-inC))<=0.00000001)*WhiteNoise.ar())+(((mag.real-inR)+(mag.imag-inC))>0.00000001)*mag.real).poll;
	c.imag=((((mag.real-inR)+(mag.imag-inC))<=0.00000001)*WhiteNoise.ar())+(((mag.real-inR)+(mag.imag-inC))>0.00000001)*mag.imag;

	out=[Duty.ar(SampleDur.ir,0,Dbufwr(c.real*fb,tB)),Duty.ar(SampleDur.ir,0,Dbufwr(c.imag*fb,tB,1))];


	OffsetOut.ar(0,(c.magnitude.clip(-1.0,1.0)*(c.theta*amt).sin));
}).add;

y=Synth(\mndS);
s.scope

)






(SynthDef(\mnd,{
	|freq=50.0,gate,amt=0.001,freeze=0,shift=1.0,below=2.0,dT=0.0,fb=2.0|
	var chain;
	var tB= LocalBuf(1);
	var osc;
	var in;
	var out;
	var chain2;
	in=Duty.ar(SampleDur.ir,0,Dbufrd(tB));
	osc=FFT(LocalBuf(2048),(amt+in));
	chain=FFT(LocalBuf(2048),in);
	chain2=PV_BinShift(chain,1, -2048+shift,1);
	chain=PV_BinShift(chain,1,shift,1);
	chain=PV_Add(chain,chain2);
	chain=PV_Mul(chain,chain);
		osc=PV_Freeze(osc,freeze);
	chain=PV_Add(chain,osc);
	chain=PV_MagBelow(chain,below);
	out= IFFT(chain)+ DelayC.ar(IFFT(chain),1.0,dT);
	out=Duty.ar(SampleDur.ir,0,Dbufwr(out*fb,tB));
	OffsetOut.ar(0,out);
}).add)



y=Synth(\mndS);
s.scope

y=Synth(\mnd)
y.set(\amt,0.9,\below,30.0.sqrt,\freeze,0,\dT,(1/48000)*6400)

y.set(\shift,-128.0,\below,1.5)
s.scope
Quarks.gui
Spectrogram
{SinOsc.ar(440)}
(w = Window.new("testing spectrogram", Rect(10,10, 600, 300)).front;
a = Spectrogram.new(w, Rect(10, 10, 580, 280));
a.start;y=Synth(\mnd))

{SinOsc.ar}.play
(w = Window.new("testing spectrogram", Rect(10,10, 600, 300)).front;
a = Spectrogram.new(w, Rect(10, 10, 580, 280));
a.start;
Synth.new(\mnd)
)
a.start
a=SpectrogramWindow.new;