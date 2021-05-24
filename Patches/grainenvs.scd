


~windowBuf=Buffer.alloc(s,1024)
x.free
x.fill(0,1024,0.3)
x.zero
Buffer.freeAll
x.plot
p="/Users/aleksandar/Music/Loopmasters.KV.Bala.Krishnan.Tabla.Sessions.WAV.REX/TSE_WAV_LOOPS/TSE_175_E/TSE_175_E_2_Tabla_Ens_2.wav"



(
{
    SendReply.kr(Impulse.kr(3), '/the_answer', [40, 41, 42, 43] + MouseX.kr, 1905);
}.play(s);
)

o = OSCFunc({ |msg| msg.postln }, '/the_answer');




~windowBuf=Buffer.alloc(s,1024);

(
~chopWindowFunc= {|size=1024,env=\hammingWindow,extend=0.5|
	var window;
	var minMax;

	size=size.clip(8,2048);
	extend=(extend.clip(0.0,1024.0)*size).asInteger;
	window=("Signal."++env++"("++ size.asString ++")").interpret;
	minMax=[window.reduce('min'),window.reduce('max')];

	window=(window)[(0..window.indexOf(minMax[1]))];

	(((window++ (minMax[1]!extend)++window.reverse)-minMax[0]).resamp1(size));
	};
    ~windowBuf.loadCollection(~chopWindowFunc.value(x.numFrames,extend:12.0 ));
)




x.plot
x.get(1022, {|msg| msg.postln});
y.plot

y=Buffer.read(s,p)
y.plot
y.readChannel(p,channels:[0])
y.zero
y.plot
y.free
y=Buffer.alloc(s,48000,1)
y.loadCollection(48000.collect({|i| ((i*1280pi)/(48000.0)).sin }))
y.plot
x.free
x.loadCollection(1024.collect({|i| ((i*4pi)/(1024.0)).sin }))
x.plot




(
SynthDef(\ghanne,{|overlap=2,envBuf= -1,winSize=0.3,freqR=1.0,mod=1.0,scale=1.0|

Out.ar(0,Warp1.ar(1,y,(Phasor.ar(1.0,SampleDur.ir*scale,0,1.0)).wrap(0.0,1.0),freqR,winSize,overlaps:overlap,envbufnum:envBuf).dup);

}).add;
)
overlap=(0.125*winSize)

a.free;
a=Synth(\ghanne,["overlap",1,"envBuf",x,\winSize,0.001])
)
x.plot
s.scope
y.plot
d.free

SendReply


(
d=(
a.free;
	a=Synth(\ghanne,["overlap",1,"envBuf",x,\winSize,0.1]);

	fork{
		var over=2.0;
	inf.do({fork{
		over=(3.rand*2).clip(1,16);
		x.loadCollection(~chopWindowFunc.value(x.numFrames,extend: (16-(over*4)).asFloat ));

		a.set(\overlap,over,\envBuf,x,\mod,0.001.exprand(1.0),\freqR,4.0,\winSize,0.125/over,\scale,1.0.exprand(3.0).poll);
	};
		(0.25/over).postln.wait;

	});



}


))