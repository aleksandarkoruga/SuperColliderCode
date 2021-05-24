

/*a=Dictionary.new

a.put(\foo,7)
a.at(\foo)
MIDIClient.destinations[3]
MIDIClient.init;

.contains("Elektron");
"loopMIDI Port" to ableton
"loopMIDI Port 1" to sc





MIDIClient.sources.at(0)  String
Int8Array[247,-9]
0xf7


"loopMIDI Port"
////////////////////////////////////////////////////////////////////////
///////////////////////Some resets//////////////////////////////////////
~midiOut.free;
~sysexIN.free;
MIDIIn.disconnectAll;
MIDIClient.disposeClient;


~phoneReceiveRefresh.free;
~phoneReceive.do({|item,i|item.free});
~phoneReceive.free;


		~address.sendMsg("/stop",1,2,2);


//SEND PATTERNLENGTH ALSO


MIDIIn.disconnectAll;
MIDIClient.disposeClient;



*/



(
//reserve machinedrum
MIDIClient.init;
////////////////////////////////////////////////////////////////////////
///////////////////////MAIN/////////////////////////////////////////////

//setup address first
~interpreterAddress=57120

)
(
//setup midi in out numbers
var source=0;
var destDict=Dictionary.new();


MIDIClient.destinations.do({
	|item,i|
	if(item.asString.contains("Elektron"),{destDict.put(\elektron,i)});
	if(item.asString.contains("loopMIDI Port"),{destDict.put(\ableton,i)});
	if(item.asString.contains("loopMIDI Port 1"),{destDict.put(\sc,i)});
});
MIDIClient.sources.do({
	|item,i|
	if(item.asString.contains("Elektron"),{source=i});
});


//START
MIDIIn.connect(0, MIDIClient.sources.at(source));
~midiOut=MIDIOut(destDict.at(\elektron));
~midiOutLive=MIDIOut(destDict.at(\ableton));
~midiOutSC=MIDIOut(destDict.at(\sc));



// receiving note on/off,cc, start/stop and clock, sending through midi loop

~address = NetAddr("127.0.0.1", ~interpreterAddress); // other interpreter
~clockM.free;
~clockM=MIDIFunc.midiClock
({
	//~address.sendMsg("/clock",1);
	~midiOutLive.midiClock();
	~midiOutSC.midiClock();
});

~start =MIDIFunc.start (
	{
		|rrc,source,val|
		~midiOutSC.start();

		//~address.sendMsg("/start",rrc,source,val);
	}
);

~stop ==MIDIFunc.stop (
	{
		|rrc,source,val|
		~midiOutSC.stop;
		//~address.sendMsg("/stop",rrc,source,val);
	}
);

// val, cc, chan, src

~cc = MIDIFunc.cc({ arg val, num, chan, src;
	~midiOutSC.control(chan,num,val);
	//~address.sendMsg("/cc",val,num,chan,src);

});


// vel, num, chan, src
~noteOn = MIDIFunc.noteOn({ arg vel, num, chan, src;
	~midiOutSC.noteOn(chan,num,vel);

	//~address.sendMsg("/noteOn",vel,num,chan,src);

});

~noteOff = MIDIFunc.noteOff({ arg vel, num, chan, src;
		~midiOutSC.noteOn(chan,num,vel);


	//~address.sendMsg("/noteOff",vel,num,chan,src);

});




~saveKit={

	~midiOut.sysex(Int8Array[0xf0, 0x00, 0x20, 0x3c, 0x02, 0x00, 0x59, ~currentKit , 0xf7]);
};


~requestDump={
//request current Pattern position
~midiOut.sysex(Int8Array[0xf0, 0x00, 0x20, 0x3c, 0x02, 0x00, 0x70, 0x04 , 0xf7])
};

~requestCurrentKit={
	~midiOut.sysex(Int8Array[0xf0, 0x00, 0x20, 0x3c, 0x02, 0x00, 0x70, 0x02 , 0xf7])
};


~translateSysex7data={
				|dumpIn,pos,length|
var f1,f2,dump=dumpIn.deepCopy;

f1=(dump[pos..(pos+(length-1))])[(8*(0..500))].removeAllSuchThat({|i|i!=nil});

f2= ((((1..7)!500)+(8*(0..500)))[(0..(f1.size-1))]).flat.clip2(length-1);
f2=(dump[pos..(pos+(length-1))])[f2];
f1=f1.do({|item,i| f1[i]=item.asBinaryDigits; f1[i].removeAt(0); });
f2=f2.do({|item,i| f2[i]=item.asBinaryDigits; f2[i][0]= f1[i/7][i%7];  });
f2=f2.flat.clump(32);
f2=f2.collect({|item,i| item.reverse});
	f2;

};



~sysexIN.free;
~sysexIN=MIDIFunc.sysex({arg ...args;
	var dump;

	dump=args[0].deepCopy;
	dump.postln;
	if(dump[6]==114,
		{
			switch(dump[7],
				2,{
					~currentKit=dump[8];
					"currentKit:".postln;
					~currentKit.post;"".postln;
					//save current Kit
					~saveKit.value();

					//request pattern dump


					~midiOut.sysex(Int8Array[0xf0, 0x00, 0x20, 0x3c, 0x02, 0x00, 0x68, ~currentPattern , 0xf7]);

				},
				4,{
					~currentPattern=dump[8];"currentPattern:".postln;
					~currentPattern.post;"".postln;
					~requestCurrentKit.value();



				},
				34,
				{
					~currentTrack=dump[8];
					"currentTrack:".postln;
					~currentTrack.post;
					"".postln;
					})
	},
		{
			if(dump[6]==103,{

				var f1,f2;
				~dump=dump.deepCopy;
				//~trigPatterns=[];
				//~trigPatterns.add(~translateSysex7data.value(dump,0x0A,74));
				//~trigPatterns.add(~translateSysex7data.value(dump,0x9DC,234));


				~machineDpatterns=[];
				~patternLength=~dump[0xb2];
				~patternLength.postln;
				~address.sendMsg("/pLength",~patternLength);
				~machineDpatterns= ~translateSysex7data.value(~dump,0x0A,74).collect({|item,i|(item++ ~translateSysex7data.value(~dump,0xAC6,74)[i])}).postln;
				~machineDpatterns.do({|item,i| ~address.sendMsg("/pattern",([i]++item).asString);  });


			/*
f1=(~dump[0x0A..(0x0A+73)])[(8*(0..1000))].removeAllSuchThat({|i|i!=nil});

f2= ((((1..7)!1000)+(8*(0..1000)))[(0..(f1.size-1))]).flat.clip2(73);
f2=(~dump[0x0A..(0x0A+73)])[f2];
f1=f1.do({|item,i| f1[i]=item.asBinaryDigits; f1[i].removeAt(0); });
f2=f2.do({|item,i| f2[i]=item.asBinaryDigits; f2[i][0]= f1[i/7][i%7];  });
f2=f2.flat;*/


//16.do({|i| ~trigPatterns=~trigPatterns.add((f2[(i*32)..((i*32)+31)]).reverse) });
				"patternArrived".postln;},{
				if(dump[6]==19,{"speed ack".postln;
//~midiOut.sysex(Int8Array[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);
//~midiOut.sysex(Int8Array[0xF0,0x00,0x20,0x3C,0x00,0x00,0x14,0x55,0x55,0x55,0x55,0x00,0x00,0x00,0x00,0xF7]);
		},{"unknown ".post;dump.postln;});});
		}
	);

});



~prepareTrigs={|arrayIn|
	var array=arrayIn.deepCopy;
	if(array.flat.size==(32*16),
		{
			var mask,array8=(0!8)!64;
			array.do({|item,i|
				item=item.reverse;
				array8[i*4]=item[0..7];
				array8[(i*4)+1]=item[8..15];
				array8[(i*4)+2]=item[16..23];
				array8[(i*4)+3]=item[24..31];

			});
			mask=array8.collect({|item|item[0]});

			//mask=array8.flop[0].postln;
			mask= Array2D.fromArray(10,7,mask.extend(70,0));
			mask=mask.rows.collect({|i|mask.rowAt(i).addFirst(0)});
			array8.do({|item,i|
				item[0]=0;
				array8[i]=item });

			mask.do({|item,i|
				array8=array8.insert(i*8,item);
			});
			array8
		}
	)

};





~sendPatterns={
	|dumpIn,patterns,position= (~currentPattern)|
var lo32,hi32,dump,loArray,hiArray;
lo32=patterns.collect({|item,i| item[0..31] });
hi32=patterns.collect({|item,i| item[32..63] });



	loArray=~prepareTrigs.value(lo32[0..15]);
hiArray=~prepareTrigs.value(hi32[0..15]);



loArray=loArray.do({|item,i|
	loArray[i]=item.convertDigits(2);
});
hiArray=hiArray.do({|item,i|
	hiArray[i]=item.convertDigits(2);
});


loArray=Int8Array.newFrom(loArray);
hiArray=Int8Array.newFrom(hiArray);




dump=dumpIn.deepCopy;
	//set track to desired destination 0-127
	dump[9]=position;
loArray.do({
	|item,i|
dump[0x0A+i]=	item;
});

hiArray.do({
	|item,i|
dump[0xAC6+i]=	item;
});







~checksum=0;
5396.do({|i| ~checksum=~checksum+ dump[i+9]  });
~checksum=~checksum.asBinaryDigits(14);


dump[5406]=~checksum[7..13].convertDigits(2);
dump[5405]=~checksum[0..6].convertDigits(2);




~midiOut.sysex(dump)
};







~weightFunc={
	|pattern,base=2|

	var size=pattern.size;
	var nBits= ((NumericalExtensions.logN(size-1,base).floor)+1);
	var mask=
	pattern.size.collect({|i|  i.asDigits(base,nBits).reverse.convertDigits(base)  });

	if(pattern.size>30,
		{
			NumericalExtensions.convertDigitsFloat((pattern[mask.order].reverse),2)

		}

		,{pattern[mask.order].reverse.convertDigits(2)})
};

~revWeightFunc={
	|num,size=16,base=2|

	var nBits= ((NumericalExtensions.logN(size-1,base).floor)+1);
	var mask=size.collect({|i|  i.asDigits(base,nBits).reverse.convertDigits(base)  });



	var maskOrdered=mask.deepCopy;

	mask.order.do({|item,i|
		/*item is the index givven by .order, i is the progressive index to pad sequences not multiple of base power*/
		maskOrdered.put(item,i)
	});



	(  (NumericalExtensions.toBinaryArray(num,size).reverse)[maskOrdered])

};



~variatePattern64={
	|pattern,base=2|

	var end=[];


	if(~patternLength<64,{end=pattern[~patternLength..63]});

	if(pattern.size==64,{
		//pattern=(pattern[(16*i)..(15+(16*i))]);
		pattern=pattern[0..(~patternLength)];

		//4.collect({|i| ~revWeightFunc.value((~weightFunc.value()+256.rand2).abs)  }).flat
		pattern=~revWeightFunc.value((~weightFunc.value(pattern,base)+256.rand2).abs,~patternLength,base.asInteger)++end
	});


	pattern;

};




~importMD=
{
//fill dump
~requestDump.value();



//fill patterns
//~machineDpatterns= ~translateSysex7data.value(~dump,0x0A,72).collect({|item,i|(item++ ~translateSysex7data.value(~dump,0xAC6,72)[i])})
};




~variateMD=
{|trackN|

	~machineDpatterns[trackN.clip(0,15)]=~variatePattern64.value(~machineDpatterns[trackN.clip(0,15)]);

	~machineDpatterns[trackN.clip(0,15)].postln;

	~sendPatterns.value(~dump,~machineDpatterns);

};





~phoneReceive=16.collect({
	|i|
	OSCFunc({ arg msg, time, addr, recvPort; if(msg[1]==1,{~variateMD.value(-1+msg[0].asString.split($_)[1].asInteger);})  }, '/button_'++(i+1).asString,recvPort:7772)

});

~phoneReceiveRefresh=OSCFunc({ arg msg, time, addr, recvPort; if(msg[1]==1,{~importMD.value();})  }, '/refresh',recvPort:7772);

~phoneReceiveNbars.free;
~phoneReceiveNbars=OSCFunc({ arg msg, time, addr, recvPort;    ~address.sendMsg("/nbars",msg[1])   }, '/nbars',recvPort:7772);



~amps=(0.0!3);
~phoneReceiveAmp.do({|i|i.free});
~phoneReceiveAmp=3.collect({
	|i|
	OSCFunc({ arg msg, time, addr, recvPort; ~amps.[msg[0].asString[5].asString.interpret-1]=msg[1];  ~address.sendMsg("/pAmp",~amps.asString)    }, '/pamp'++(i+1).asString,recvPort:7772)

});


~importMD.value();

"sysex inited".postln;

)
//request current track position
