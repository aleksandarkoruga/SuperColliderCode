NeuralNetFb
{
	var <>threshold,<nNeurons,<nLayers,<xMatrix,<weightMatrix,<biasMatrix;


	*new
	{    |neurons,layers,threshold|
		^super.new.init(neurons,layers,threshold)
	}

	init
	{
		|neurons,layers,thresh=0.5|
		nNeurons=neurons;
		nLayers=layers;
		threshold=thresh;
		biasMatrix=this.prGenerateMatrix([nNeurons,nLayers]);
		weightMatrix=this.prGenerateMatrix([nNeurons,nNeurons,nLayers]);
		xMatrix=this.prGenerateMatrix([nNeurons,nLayers]);
	}
	next
	{
		this.neuronFunc();
		^xMatrix[nLayers-1];

	}

	prGenerateMatrix{
	|inSize|

	var rnd={rrand(-1.0,1.0)};



		inSize.do({
		|item,i|
		rnd=rnd!item;
	});
	^rnd
	}

	neuronFunc{


	var outX,prevX,outBias,outWeight,invDiff;
	outX=xMatrix.deepCopy;
	outBias=biasMatrix.deepCopy;
	outWeight=weightMatrix.deepCopy;
	xMatrix=xMatrix.rotate(1);

	biasMatrix.do({|item,i|var layer=i;
		item.do({
			|item,i|
			var neuron=i;
				prevX=outX[layer][neuron];
				outX[layer][neuron]= ((weightMatrix[layer][neuron]*xMatrix[layer]).sum+item).tanh;
				invDiff=(1.0-(((outX[layer][neuron]-prevX).abs)*0.5));
				if(invDiff >= threshold,
				{
					outBias[layer][neuron]=(item+((invDiff/nNeurons)*rrand(-1.0,1.0))).clip(-1.0,1.0);
					outWeight[layer][neuron]=(weightMatrix[layer][neuron]+({rrand(-1.0,1.0)}!nNeurons).normalizeSum(invDiff)).clip(-1.0,1.0);

			});
	})
	});

	xMatrix=outX;
	biasMatrix=outBias;
	weightMatrix=outWeight;


}


}