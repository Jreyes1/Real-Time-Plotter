// Array helper functions

void initializeArray(ArrayList<float[][]> dataArrayList) {
  for (float[][] dataArray : dataArrayList)
    initializeArray(dataArray);
}

void initializeArray( float[][] array) {
  for (int i = 0; i < array.length; i++) {
    for (int j = 0; j < array[0].length; j++) {
      array[i][j] = 0;
    }
  }
}
void initializeArray( int[][] array) {
  for (int i = 0; i < array.length; i++) {
    for (int j = 0; j < array[0].length; j++) {
      array[i][j] = 0;
    }
  }
}
void initializeArray( int[] array) {
  for (int i = 0; i < array.length; i++) {
    array[i] = 0;
  }
}

void initializeArray( float[] array) {
  for (int i = 0; i < array.length; i++) {
    array[i] = 0;
  }
}

void shiftLeft (float [][] array) {
  // iterating through variables
  for (int i = 0; i < array.length; i++) {
    // Iterate through variable data
    for (int j = 0; j < array[0].length-1; j++) {
      array[i][j] = array[i][j+1];
    }
  }
}

void shiftLeft(ArrayList<float[][]> arrays) {
  // Find array with most variables
  int biggest = Integer.MIN_VALUE; 
  int arraySize;
  for (float[][] array : arrays) {
    arraySize = array.length;
    if (arraySize > biggest)
      biggest =arraySize;
  }
  // Iterate through variables
  for (int i = 0; i < biggest; i++) {
    // Iterate through the data
    for (int j=0; j < arrays.get(0)[0].length-1; j++) {
      // Iterate through the data arrays
      for (float[][] array : arrays) { 
        if (i < array.length){
          array[i][j] = array[i][j+1];
        }
      }
    }
  }
}



void updateArray ( float[][] array, String[] data) {
  for (int i = 0; i < array.length; i++) {
    //for (int j = 0; j < array[0].length; j++) {
      array[i][array[0].length-1] = float(data[i]);
    //}
  }
}

void updateArray(ArrayList<float[][]> arrays, String[] data){
  // find number of total variables graphs will be reading and compare to number of data points
  int numVariables = 0;
  for (float[][] array: arrays){
    numVariables += array.length;
  }

  // Note: last read character ("\r") is not counted
  assert numVariables == data.length-1: "Number of total graph variables != number of read data points";
  
  // Store read data into data arrays by the order they are stored in the list
  int variableIndex = 0;
  for (int i = 0; i < arrays.size();i++){
  //for (float[][] array: arrays){
     for (int j = 0; j < arrays.get(i).length; j++) {
        arrays.get(i)[j][arrays.get(i)[j].length-1] = float(data[variableIndex]);
        //autoScale(graphs.get(i),float(data[variableIndex]));
        variableIndex++;
     }
  }
  
}
