{ |x| sin(x) }.plotGraph(300,0,2*pi);


(
i = Image.color(400, 400, Color.white());

x={
	arg v=[0,0],k=4.0;

v[0]=(v[0]+(k*v[1].sin))%2pi;
v[1]=(v[1]+v[0])%2pi;
v
})


(
var t=[-1,1.0];
var pix;

1000.do({|i|var ix=i;1000.do({|iy|  t=[ix/1000.0,iy/1000.0].postln;

	8000.do(
{
			var pos=[0,0];
			t= x.value(t);


			pix=l.getPixel(((t[0]*(400.0/2pi))).asInteger.postln,((t[1]*(400.0/2pi))).asInteger.postln);


	l.setPixel( pix+1,((t[0]*(400.0/2pi))).asInteger,((t[1]*(400.0/2pi))).asInteger)

});

})});




)

l.plot
i.getPixel(200,200)
i.setPixel(45,200,200)
l = Image.color(400, 400, Color.white());
i.plot

