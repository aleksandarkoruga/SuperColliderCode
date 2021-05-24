
(Scale.choose.ratios.collect({|item|

	var harm=Scale.at(\major).ratios;
	var min;
	harm=harm.absdif(item).round(0.0001);
	min=harm.reduce('min').postln;
	harm.indexOf(min).postln;


})+1)

discrete

absdif.reduce('min')
[5,6,7,8].reduce({|... args|args.postln})
2.absdif(4)


[ 0, 1.9778531983433, 1.9660084169634, 2.2142857142857, 1.7272727272727, 1.9887937443212, 1.9897985710122 ].reduce('min')