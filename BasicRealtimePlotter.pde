// import libraries
import java.awt.Frame;
import java.util.List;
import java.util.ArrayList;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */

// Time settings
int maxTime = 10000;       // msec, max time then reloops
int lastTime = 0;
int numXPoints = 500;      // number of points in x axis
int readIndex = 0;         // loop variable for sampling rate calculation
int updateAxisTime = 100;  // update axis time scale every 100 readings 
int readAxisTimeIndex = 0; // loop variable for updating x-axis label

// Serial Port settings
String serialPortName = "COM5";    // serial port to connect to
boolean mockupSerial = true;       // to debug without real serial port
Serial serialPort;                 // Serial port object
byte[] inBuffer = new byte[100];   // holds serial message

// interface Library
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

// Plot object and associated data array
String[] variableLabels = {"accel", "gyro", "filtered"};
Graph rollPlot = new Graph(225, 60, 600, 175, color(20, 20, 200), "Roll Angle", "Time(s)", "Theta", 3, variableLabels);         
float[][] rollPlotData = new float[rollPlot.numVariables][numXPoints];             // 2D array of plotted data

String[] variableLabels2 = {"a","b","c"};
Graph LineGraph = new Graph(225, 375, 600, 175, color (20, 20, 200), "graph2","Time(s)","Value",3,variableLabels);
float[][] graph2Data = new float[LineGraph.numVariables][numXPoints];

// List and arrays to hold plots, plot names, plot number of variables, and 2D data arrays
List<Graph> graphList = new ArrayList<Graph>();
ArrayList<float[][]> dataArrayList = new ArrayList<float[][]>();

// Number of variables and x-axis number of points
//float[][] lineGraphValues = new float[6][numXPoints];
float[] sampleNumbers = new float[numXPoints];
color[] graphColors = new color[6];

// For calcuating rolling average of the calculated sampling rate
int numReadings = 30;                              // num of readings used in average
float[] timeReadings = new float[numReadings];     // array to hold readings
float totalTime = 0;                               // running total
float samplingRate = 0;                            // average of readings 

// helper for saving the executing path
String topSketchPath = "";

void setup() {
  surface.setTitle("Real Time Plotter");
  size(890, 920);

  // set Line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // settings save file
  topSketchPath = sketchPath();

  // Create the JSON file if it currently does not exist
  String jsonFileName = "plotter_config.json";
  File f = new File(sketchPath(jsonFileName));
  if (!f.exists()) {
    JSONObject json = new JSONObject();
    saveJSONObject(json, topSketchPath+"/"+jsonFileName);
  }

  // load JSON file
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // Add graphs to graph list, NOTE: this order dicates the order data is stored into graph variables
  graphList.add(rollPlot);
  graphList.add(LineGraph);

  // Add graph data array to data array list
  dataArrayList.add(rollPlotData);
  dataArrayList.add(graph2Data);

  // Initialize graph arrays
  initializeArray(dataArrayList);
  initializeArray(timeReadings);
  for (int i = 0; i < sampleNumbers.length; i++)
    sampleNumbers[i] = i;

  // Build the gui
  cp5 = new ControlP5(this);
  createGUI(graphList);

  setInitialChartSettings(graphList);
  //setChartSettings(rollPlot);

  // start serial communication
  if (!mockupSerial) {
    serialPort = new Serial(this, serialPortName, 115200);
  } else
    serialPort = null;
}


void draw() {

  // Find the Elapsed Time from last sample
  int currTime = millis() % maxTime; // to avoid overflowing issues
  if (currTime < lastTime)
    lastTime = 0;
  int deltaT = currTime - lastTime;
  lastTime = currTime;

  // calcuate running average of sampling rates
  totalTime = totalTime - timeReadings[readIndex]; // subtract reading in existing index
  timeReadings[readIndex] = deltaT;                // read in deltaT to array of deltaT's
  totalTime = totalTime + timeReadings[readIndex]; // add deltaT to total
  readIndex = readIndex + 1;                       // advance index

  // wrap around to beginning if at the end of the array
  if (readIndex >= numReadings)
    readIndex = 0;

  // calculate the average sampling rate
  samplingRate = totalTime/numReadings;

  // Change axis time scale after 100 data readings
  if (readAxisTimeIndex == 0) {
    // Update x-axis range on plot
    int time = -int((samplingRate*numXPoints)/1000);
    changeXRange(graphList, time);
  }

  // update x-axis update counter and reset if necessary
  readAxisTimeIndex++;
  if (readAxisTimeIndex > updateAxisTime)
    readAxisTimeIndex =0;


  /* Read serial and update values */
  if (mockupSerial || serialPort.available() > 0) {
    String myString = "";
    if (!mockupSerial) {
      try {
        serialPort.readBytesUntil('\r', inBuffer);
      }
      catch (Exception e) {
      }
      myString = new String(inBuffer);
    } else {
      myString = mockupSerialFunction();
    }


    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');

    // Shift values left to simulate moving plot
    shiftLeft(dataArrayList);

    // Add data from packet that was read to graph arrays
    updateArray( dataArrayList, nums);
    
    
  }
  // draw the line graphs
  drawGraphs(graphList,dataArrayList);

}


void drawGraphs(List<Graph> graphs, ArrayList<float[][]> dataArrays) {
  background(255);
  
  // Iterate through graphs
  for (int i = 0; i < graphs.size(); i++) {
    // Iterate through variables
    graphs.get(i).DrawAxis();
    for (int j = 0; j < dataArrays.get(i).length; j++) {
      graphs.get(i).GraphColor = graphColors[j];
      // Only plot line if toggle switch indicates on
      String toggleSwitch = "toggle"+Integer.toString(i)+"_"+Integer.toString(j);
      if (int(getPlotterConfigString(toggleSwitch)) == 1) {
        graphs.get(i).LineGraph(sampleNumbers, dataArrays.get(i)[j]);
      }
    }
  }
}


void setInitialChartSettings(List<Graph> graphs){
 for (Graph graph: graphs){
  graph.xDiv = 20;
  graph.xMax = 0;
  graph.xMin = -10;
  graph.yMax = 10;
  graph.yMin = -10;
 }
  
}


    
  


// Function for updating the x-ranges
void changeXRange(Graph graph, int time) {
  graph.xMin=time;
}
void changeXRange(List<Graph> graphList, int time) {
  for (Graph graph : graphList) {
    graph.xMin = time;
  }
}


// Create the GUI Interface for an individual plot
void createGUI(Graph graph, String graphName, int numVariables) {

  // On/Off Controls
  int x; 
  int y;
  x = graph.xPos - 170; 
  y = graph.yPos;
  cp5.addTextlabel("label").setText("ON/OFF").setPosition(x, y-20).setColor(0);
  for (int i =0; i < numVariables; i++) {
    cp5.addToggle(graphName+Integer.toString(i)).setPosition(x, y).setValue(int(createPlotterConfigString(graphName+Integer.toString(i), "1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[i]);
    y = y + 35;
  }
}

// Create the GUI interface for multiple plots 
void createGUI(List<Graph> graphs) {
  int x; 
  int y;

  // Generate GUI controls for each grah
  for (int i = 0; i < graphs.size(); i++) {
    x = graphs.get(i).xPos - 220; 
    y = graphs.get(i).yPos;

    // On/Off text label
    cp5.addTextlabel("graph" + Integer.toString(i)).setText("ON/OFF").setPosition(x, y-20).setColor(0);

    for (int j =0; j < graphs.get(i).numVariables; j++) {

      assert graphs.get(i).variableLabels.length == graphs.get(i).numVariables: 
      "Number of variables" + 
        " does not match number of variable labels";

      // generate labels and text, note: The text labels the user sees can be repeated but the cp5 labels cannot 
      String variableTextLabel = "variabletext"+Integer.toString(i) + "_" + Integer.toString(j);  // Unique Variable name text label
      String variableTextLabel_user = graphs.get(i).variableLabels[j];                 // Variable text that will show up
      String toggleLabel = "toggle"+Integer.toString(i) + "_" + Integer.toString(j);              // Unique Toggle Switch label

      // Create GUI components
      cp5.addTextlabel(variableTextLabel).setText(variableTextLabel_user).setPosition(x+50, y).setColor(0);
      cp5.addToggle(toggleLabel).setPosition(x, y).setValue(int(createPlotterConfigString(toggleLabel, "1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[j]);
      y = y + 35;
    }
  }
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  //setChartSettings();
}

// Create JSON objects
String createPlotterConfigString(String id, String parameter) {
  if (!plotterConfigJSON.hasKey(id)) {
    plotterConfigJSON.setString(id, parameter);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  return plotterConfigJSON.getString(id);
}


// Get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
