function dataOut = bubbleSort(data)
 y=data;
for i = 1:size(y,2)
	for j =1: size(y,2)
		if(y(i)<y(j))
		 	tmp = y(i);
			y(i)=y(j);
			y(j)=tmp;
		end
	end
end
dataOut = y;

