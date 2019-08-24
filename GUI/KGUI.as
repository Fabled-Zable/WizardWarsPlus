
/*   License   
© 2014-2015 Zen Laboratories

This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/


enum DragEventType
{
   DragStarted,
   DragMove,
   DragFinished
}

//  here is how you can add handlers for events on UI elements.
//  Your handler should be a function (you specify it's name here)
//  defined in the same file or in the class (prolly)

//	It must have the same signature as mentioned in the top part of KGUI.as

//	button.addClickListener(OnButtonClicked);
//	button.addPressStateListener(OnButtonPressed);
//	button.addHoverStateListener(OnButtonHoverStateChanged);
//	window.addDragEventListener(OnDragEvent);

	// Click callback definition
	// Parameters:
	// X - Mouse position X relative to element
	// Y - Mouse position Y relative to element
	// button - Mouse button descriptor 
	// Source
	funcdef void CLICK_CALLBACK(int, int, int,IGUIItem@);

	// Hover state changed callback definition
	// Parameters:
	// isHovered - Is the element hovered?
	// Source
	funcdef void HOVER_STATE_CHANGED_CALLBACK(bool,IGUIItem@);

	// Press state changed callback definition
	// Parameters:
	// isPressed - Is the element pressed?
	// int - What mouse button caused the event
	// Source
	funcdef void PRESS_STATE_CHANGED_CALLBACK(bool, int,IGUIItem@);

	// Drag event callback definition
	// Parameters:
	// DragEventType - see DragEventType Enum
	// Vec2f - mouse position
	// Source
	funcdef void DRAG_EVENT_CALLBACK(int, Vec2f,IGUIItem@);

	funcdef void SLIDE_EVENT_CALLBACK(int, Vec2f,IGUIItem@);



interface IGUIItem{


	//Properties
	Vec2f position {get; set;}
	Vec2f localPosition {get; set;} 
	Vec2f size {get; set;}
	string name {get; set;}
	string mod {get; set;}
	bool isEnabled {get; set;}
	bool isDragable {get; set;}
	bool isHovered {get; set;}
	int draggingThresold {get; set;}
	bool isClickedWithRButton{get; set;}
	bool isClickedWithLButton{get; set;}
	bool locked{get; set;}
	//Methods
	void draw();

	void addChild(IGUIItem@ child);
	void removeChild(IGUIItem@ child);
	void clearChildren();

	//Saving GUI Props to CFG:
	//By default only local position and size are (de)serialized. Override those to (de)serialize custom things.
	void loadPos(const string modName,const f32 def_x,const f32 def_y);
	void savePos(const string modName);
	bool getBool(string save,const string modName);
	void saveBool(string save,const bool lock,const string modName);

	//Listeners controls
	void addClickListener(CLICK_CALLBACK@ listener);
	void removeClickListener(CLICK_CALLBACK@ listener);
	void clearClickListeners();

	void addHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener);
	void removeHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener);
	void clearHoverStateListeners();

	void addPressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener);
	void removePressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener);
	void clearPressStateListeners();

	void addDragEventListener(DRAG_EVENT_CALLBACK@ listener);
	void removeDragEventListener(DRAG_EVENT_CALLBACK@ listener);
	void clearDragEventListeners();

	void addSlideEventListener(SLIDE_EVENT_CALLBACK@ listener);
	void removeSlideEventListener(SLIDE_EVENT_CALLBACK@ listener);
	void clearSlideEventListeners();

}

class GenericGUIItem : IGUIItem{
	//Debug mode -draws colored rectangles over entire size of object to help for lining up.
	private bool Debug = false;
	SColor DebugColor;


	//config properties
	Vec2f position {
		get { return _position;} 
		set { _position = value;}
	}
	Vec2f localPosition {
		get { return _localPosition;} 
		set { _localPosition = value;}
	} 
	Vec2f size {
		get { return _size;} 
		set { _size = value;}
	}
	string name {
		get { return _name;} 
		set { _name = value;}
	}
	string mod {
		get { return _mod;} 
		set { _mod = value;}
	}
	bool isEnabled {
		get { return _enabled;} 
		set { _enabled = value;}
	}
	bool isDragable {
		get { return _isDragable;} 
		set { _isDragable = value;}
	}
	int draggingThresold {
		get { return _dragThresold;} 
		set { _dragThresold = value;}
	}
	bool isHovered{
		get { return _isHovered;} 
		set { _isHovered = value;}
	}
	bool isClickedWithRButton{
		get { return _isClickedWithRButton;} 
		set { _isClickedWithRButton = value;}
	}
	bool isClickedWithLButton{
		get { return _isClickedWithLButton;} 
		set { _isClickedWithLButton = value;}
	}
	bool locked{
		get { return _isLocked;} 
		set { _isLocked = value;}
	}
	//backing fields
	private Vec2f _size;
	private Vec2f _localPosition;
	private bool _enabled = true;
	private string _name;
	private string _mod;
	private Vec2f _position;
	private bool _isDragable = false;
	private int _dragThresold = 2;
	private bool _isLocked = false;

	//Animation
	private int[] _frameIndex;
	private int _animFreq;
	private int _frame;
	private string _image;
	private Vec2f _iDimension;

	//Mouse states ( simple cache, polly will be removed later)
	private bool _mouseLeftButtonPressed  = false;
	private bool _mouseLeftButtonReleased  = false;
	private bool _mouseRightButtonPressed  = false;
	private bool _mouseRightButtonReleased  = false;
	private bool _mouseLeftButtonHold  = false;
	private bool _mouseRightButtonHold  = false;
	private Vec2f _mousePosition;

	//GUI Element states
	private bool justPressedL = false;
	private bool justPressedR = false;	
	private bool _isHovered = false;
	private int toolTipDisp = 0;
	private int toolTipTimer = 0;
	private string toolTip;	
	private SColor tipColor;		
	private bool _isPressedWithLButton = false;
	private bool _isPressedWithRButton = false; 
	private bool _isClickedWithLButton = false;
	private bool _isClickedWithRButton = false;
	private bool _isDragging = false;
	private bool _isDragPossible = false;
	private Vec2f _dragStartPosition ;
	private Vec2f _dragCurrentPosition;
	private bool _isSliding = false;
	private bool _isSlidePossible = false;
	private Vec2f _SlideStartPosition ;
	private Vec2f _SlideCurrentPosition;
	private Vec2f _startPos;
	private Vec2f _startSlidePos;

	//Children and listeners
	private IGUIItem@[] children;
	private CLICK_CALLBACK@[] _clickListeners;
	private HOVER_STATE_CHANGED_CALLBACK@[] _hoverStateListeners;
	private PRESS_STATE_CHANGED_CALLBACK@[] _pressStateListeners;
	private DRAG_EVENT_CALLBACK@[] _dragEventListeners;
	private SLIDE_EVENT_CALLBACK@[] _slideEventListeners;


	GenericGUIItem(Vec2f v_localPosition, Vec2f v_size){
		localPosition = v_localPosition;
		position = localPosition;
		size = v_size;
	}

	/* Children GUI elements controls */

	void addChild(IGUIItem@ child){
		children.push_back(child);
	}

	void removeChild(IGUIItem@ child){
		int ndx = children.find(child);
		if(ndx>-1)
			children.removeAt(ndx);
	}

	void clearChildren(){
		for(int i = 0; i < children.length; i++){
			children.removeAt(i);
		}	
	}

	/* Listener controls */

	void addClickListener(CLICK_CALLBACK@ listener){
		_clickListeners.push_back(listener);
	};

	void removeClickListener(CLICK_CALLBACK@ listener){
		int ndx = _clickListeners.find(listener);
		if(ndx>-1)
			_clickListeners.removeAt(ndx);	
	}

	void clearClickListeners(){
		for(int i = 0; i < _clickListeners.length; i++){
			_clickListeners.removeAt(i);
		}	
	}

	void addHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener){
		_hoverStateListeners.push_back(listener);
	};

	void removeHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener){
		int ndx = _hoverStateListeners.find(listener);
		if(ndx>-1)
			_hoverStateListeners.removeAt(ndx);	
	}

	void clearHoverStateListeners(){
		for(int i = 0; i < _hoverStateListeners.length; i++){
			_hoverStateListeners.removeAt(i);
		}	
	}

	void addPressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener){
		_pressStateListeners.push_back(listener);
	}

	void removePressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener){
		int ndx = _pressStateListeners.find(listener);
		if(ndx>-1)
			_pressStateListeners.removeAt(ndx);	
	}

	void clearPressStateListeners(){
		for(int i = 0; i < _pressStateListeners.length; i++){
			_pressStateListeners.removeAt(i);
		}	
	}

	void addDragEventListener(DRAG_EVENT_CALLBACK@ listener){
		_dragEventListeners.push_back(listener);
	}
	void removeDragEventListener(DRAG_EVENT_CALLBACK@ listener){
		int ndx = _dragEventListeners.find(listener);
		if(ndx>-1)
			_dragEventListeners.removeAt(ndx);		
	}
	void clearDragEventListeners(){
		for(int i = 0; i < _dragEventListeners.length; i++){
			_dragEventListeners.removeAt(i);
		}	
	}

	void addSlideEventListener(SLIDE_EVENT_CALLBACK@ listener){
		_slideEventListeners.push_back(listener);
	}
	void removeSlideEventListener(SLIDE_EVENT_CALLBACK@ listener){
		int ndx = _slideEventListeners.find(listener);
		if(ndx>-1)
			_slideEventListeners.removeAt(ndx);		
	}
	void clearSlideEventListeners(){
		for(int i = 0; i < _slideEventListeners.length; i++){
			_slideEventListeners.removeAt(i);
		}	
	}

	private void invokeClickListeners(int x, int y, int buttonCode){
		for(int i = 0; i < _clickListeners.length; i++){
			_clickListeners[i](x,y,buttonCode,this);
		}
		if (_clickListeners.length > 0){
			if (_isPressedWithLButton){
				//getLocalPlayer().getBlob().set_bool("GUIEvent",true);
			}
			//else //getLocalPlayer().getBlob().set_bool("GUIEvent",false);	
		}
	}

	private void invokeHoverStateListeners(bool isHovered){
		for(int i = 0; i < _hoverStateListeners.length; i++){
			_hoverStateListeners[i](isHovered,this);
		}	
	}

	private void invokePressStateListeners(bool isPressed, int buttonCode){

		for(int i = 0; i < _pressStateListeners.length; i++){
			_pressStateListeners[i](isPressed,buttonCode,this);
		}	
	}

	private void invokeDragEventListeners(int eventType, Vec2f mousepos){
		for(int i = 0; i < _dragEventListeners.length; i++){
			_dragEventListeners[i](eventType,mousepos,this);
		}	
	}

	private void invokeSlideEventListeners(int eventType, Vec2f mousepos){
		for(int i = 0; i < _slideEventListeners.length; i++){
			_slideEventListeners[i](eventType,mousepos,this);
		}	
	}

	//*Made by Labz*//
	//*worked on by Sini and Voper*//
	
	bool calculateHover(){
		CControls@ controls = getControls();
		Vec2f mouseScrPos= getControls().getMouseScreenPos();
		Vec2f lt = position;
		Vec2f br = position+size;
		return 
			mouseScrPos.x >= lt.x && 
			mouseScrPos.x <=br.x &&
			mouseScrPos.y >= lt.y && 
			mouseScrPos.y <=br.y;
	}

	//Mouse magic
	
	void draw(){




		//State updates. WARNING: The order of evaluation is important!
		updateMouseStates();
		updateHoverStates();
		updateClickStates();
		updatePressedStates();
		updateDraggingStates();
		updateSliderStates();


		drawSelf();
		if(Debug) GUI::DrawRectangle(position, position+size,DebugColor);
		//draw children
		for(int i = 0; i < children.length; i++)
		{
			if(children[i] is null) continue;
			if(!children[i].isEnabled) continue;
			children[i].position = position+children[i].localPosition;
			children[i].draw();
		}
		updateToolTipState();
	

	}

	void drawSelf(){

	}

	void slide(){

	}

	//Possible optimization : pass control states from the parent
	private void updateMouseStates(){
		CControls@ controls = getControls();
		//_mouseLeftButtonPressed = controls.isKeyJustPressed(KEY_LBUTTON);
		_mouseLeftButtonReleased = controls.isKeyJustReleased(KEY_LBUTTON);
		//_mouseRightButtonPressed = controls.isKeyJustPressed(KEY_RBUTTON);
		_mouseRightButtonReleased = controls.isKeyJustReleased(KEY_RBUTTON);
		_mouseLeftButtonHold = controls.isKeyPressed(KEY_LBUTTON);
		_mouseRightButtonHold = controls.isKeyPressed(KEY_RBUTTON);
		_mousePosition = controls.getMouseScreenPos();

		//Might get replaced, currently more reliable at finding just pressed state then controls.isKeyJustPressed()
		//due to way KAG does calculation there.
		if(_mouseLeftButtonHold && !justPressedL){
			_mouseLeftButtonPressed = true;
			justPressedL = true;
		}
		else if (justPressedL) _mouseLeftButtonPressed = false;
		if (!_mouseLeftButtonHold) justPressedL = false;
		if(_mouseRightButtonHold && !justPressedR){
			_mouseRightButtonPressed = true;
			justPressedR = true;
		}
		else if (justPressedR) _mouseRightButtonPressed = false;
		if (!_mouseRightButtonHold) justPressedR = false;
	}

	void updateHoverStates(){
		bool newHovered = calculateHover();
		if(newHovered != _isHovered){
			if(newHovered && !_isHovered){
				invokeHoverStateListeners(true);
			} else {
				invokeHoverStateListeners(false);
				toolTipTimer = 0;
			}
			_isHovered = newHovered;
		}
	}

	void updatePressedStates(){
		
		if(_isHovered && _mouseLeftButtonHold && !_isPressedWithLButton){
			_isPressedWithLButton = true;
			invokePressStateListeners(true, KEY_LBUTTON);
		}

		if(_isHovered && _mouseRightButtonHold && !_isPressedWithRButton){
			_isPressedWithRButton = true;
			invokePressStateListeners(true, KEY_RBUTTON);
		}

		if(!_mouseLeftButtonHold && _isPressedWithLButton){
			_isPressedWithLButton = false;
			invokePressStateListeners(false, KEY_LBUTTON);
		}
		
		if(!_mouseRightButtonHold && _isPressedWithRButton){
			_isPressedWithRButton = false;
			invokePressStateListeners(false, KEY_RBUTTON);
		}

		if(!_isHovered && _isPressedWithRButton){
			_isPressedWithRButton = false;
			invokePressStateListeners(false,KEY_RBUTTON);
		}

		if(!_isHovered && _isPressedWithLButton){
			_isPressedWithLButton = false;
			invokePressStateListeners(false,KEY_LBUTTON);
		}
	}

	void updateDraggingStates(){
		if(!isDragable || !isEnabled || _isLocked){
			_isDragging = false;
			_isDragPossible = false;
			return;
		}
		if(isHovered && _mouseLeftButtonPressed){
			_dragStartPosition = _mousePosition;
			_isDragPossible = true;
		}
		if(_isDragging && _dragCurrentPosition != _mousePosition){
			_dragCurrentPosition = _mousePosition;
			invokeDragEventListeners(DragMove,_dragCurrentPosition);
			dragLocation();
		}
		if(_isDragging && !_mouseLeftButtonHold){
			_isDragging = false;
			invokeDragEventListeners(DragFinished,_dragCurrentPosition);
			_isDragPossible = false;
		}
		if(_isDragPossible && !_mouseLeftButtonHold){
			_isDragPossible = false;
		}
		if(!_isDragging && _isDragPossible && (_dragStartPosition - _mousePosition).Length() > draggingThresold){
			_isDragging = true;
			_isDragPossible = false;
			_startPos = position;
			invokeDragEventListeners(DragStarted,_dragStartPosition);
		}
	}

	void updateSliderStates(){
		if(!isEnabled || _isLocked){
			_isSliding = false;
			_isSlidePossible = false;
			return;
		}
		if(isHovered && _mouseLeftButtonPressed){
			_SlideStartPosition = _mousePosition;
			_isSlidePossible = true;
		}
		if(_isSliding && _SlideCurrentPosition != _mousePosition){
			_SlideCurrentPosition = _mousePosition;
			invokeSlideEventListeners(DragMove,_SlideCurrentPosition);
			slide();
		}
		if(_isSliding && !_mouseLeftButtonHold){
			_isSliding = false;
			invokeSlideEventListeners(DragFinished,_SlideCurrentPosition);
			_isSlidePossible = false;

		}
		if(_isSlidePossible && !_mouseLeftButtonHold){
			_isSlidePossible = false;
		}
		if(!_isSliding && _isSlidePossible && (_SlideStartPosition - _mousePosition).Length() > draggingThresold){
			_isSliding = true;
			_isSlidePossible = false;
			_startSlidePos = getSliderPos();
			invokeSlideEventListeners(DragStarted,_SlideStartPosition);
		}
	}

	Vec2f getSliderPos(){
		return Vec2f(0,0);
	}

	void dragLocation(){
		Vec2f movement;
		if(_dragCurrentPosition.x > _dragStartPosition.x){movement.x = _startPos.x + (_dragCurrentPosition.x - _dragStartPosition.x);}
		if(_dragCurrentPosition.x <= _dragStartPosition.x){movement.x = _startPos.x - (_dragStartPosition.x - _dragCurrentPosition.x);}
		if(_dragCurrentPosition.y > _dragStartPosition.y){movement.y = _startPos.y + (_dragCurrentPosition.y - _dragStartPosition.y);}
		if(_dragCurrentPosition.y <= _dragStartPosition.y){movement.y = _startPos.y - (_dragStartPosition.y - _dragCurrentPosition.y);}
		position = movement;
	}

	void updateClickStates(){
		if (_isLocked)return;
		_isClickedWithLButton = false;
		_isClickedWithRButton = false;
		if(_isPressedWithLButton && !_mouseLeftButtonHold && isHovered && !_isDragging){
			invokeClickListeners(_mousePosition.x,_mousePosition.y,KEY_LBUTTON);
			_isClickedWithLButton = true;
		}
		if(_isPressedWithRButton && !_mouseRightButtonHold && isHovered){
			invokeClickListeners(_mousePosition.x,_mousePosition.y,KEY_RBUTTON);
			_isClickedWithRButton = true;
		}
	}

	//Animation frame updating logic
	void updateAnimationState(){
		if(getGameTime() % _animFreq == 0)
		{
			_frame = _frame + 1;
			if (_frame >= _frameIndex.length) _frame=0;
		}
	}	

	//ToolTip
	void updateToolTipState()
	{
		if (_isHovered == true && toolTipTimer < toolTipDisp) {
			if(getGameTime() % getTicksASecond() == 0)
			{
				toolTipTimer++;
			}
		}
		if (_isHovered == true && toolTipTimer >= toolTipDisp){ dispToolTip();}
	}

	void setToolTip(string _tip, int _toolTipDisp, SColor _tipColor)
	{
		toolTip = _tip;
		toolTipDisp = _toolTipDisp; //Time (roughly in seconds) after item is hovered before tip displays 
		tipColor = _tipColor;
	}

	void dispToolTip()
	{
		Vec2f mouseScrPos= getControls().getMouseScreenPos()+Vec2f(18,0);
		Vec2f tipSize;
		GUI::GetTextDimensions(toolTip, tipSize);
		GUI::DrawRectangle(mouseScrPos, mouseScrPos+tipSize*1.5f,SColor(200,64,64,64));
		drawRulesFont(toolTip,tipColor,mouseScrPos,mouseScrPos + Vec2f(20,15),false,false);
	}
	/* Serialization to CFG */
	/* 
		Those methods can be overriden to allow serialization of custom properties
		on custom items
	*/

	//Loading GUI position info from config
	void loadPos(const string modName,const f32 def_x,const f32 def_y)
	{
		if (getNet().isClient())
		{
			string configstr = "../Cache/"+modName+"_KGUI.cfg";
			ConfigFile cfg = ConfigFile( configstr );
			f32 x = cfg.read_f32(name+"_x",def_x);
			f32 y = cfg.read_f32(name+"_y",def_y);
			position = Vec2f(x,y);
		}
	}

	//Saving Gui position info to config
	void savePos(const string modName)
	{
		if (getNet().isClient())
		{
			print("save:" + name +" "+ modName);
			ConfigFile cfg = ConfigFile( "../Cache/"+modName+"_KGUI.cfg" );
			cfg.add_f32(name+"_x", position.x);
			cfg.add_f32(name+"_y", position.y);
			cfg.saveFile(modName+"_KGUI.cfg");
		}
	}

	//Getting Locked GUI info from config
	bool getBool(string save,const string modName = "Default")
	{ 
		if (getNet().isClient())
		{
			string configstr = "../Cache/"+modName+"_KGUI.cfg";
			ConfigFile cfg = ConfigFile( configstr );
			return cfg.read_bool(save, true);
		}
		else {return false;}
	}

	//Setting Locked GUI info to config
	void saveBool(string save,const bool value,const string modName = "Default")
	{
		if (getNet().isClient())
		{
			ConfigFile cfg = ConfigFile( "../Cache/"+modName+"_KGUI.cfg" );
			cfg.add_bool(save, value);
			cfg.saveFile(modName+"_KGUI.cfg");
		}
	}

	string textWrap(const string text_in)
	{
		string temp = "";
		const int letters = size.x/9;
		int counter = 0;
		string[]@ tokens = text_in.split(" ");
		for(int i = 0; i <tokens.length; i++){ //First pass based on spaces
			counter += tokens[i].length();

			string[]@ check = tokens[i].split("\n"); //Check for manual new lines
			if (check.length() > 1){temp += tokens[i];counter = tokens[i].length();}
			else if (counter <= letters){temp += tokens[i];}
			else {temp += "\n" + tokens[i]; counter = tokens[i].length();}
			temp += " ";
		}


		return temp;
	}
}

class Window : GenericGUIItem{
	int type;

	//In constructor you can setup any additional inner UI elements
	Window(Vec2f _position,Vec2f _size, int _type = 0, string _name = ""){
		super(_position,_size);
		name = _name;
		type = _type;
		DebugColor = SColor(155,217,2,0);
	}

	Window(string _name, Vec2f _position,Vec2f _size){ //backwards compatiblity, will be removed soon
		super(_position,_size);
		name = _name;
		DebugColor = SColor(155,217,2,0);
	}



	//Override this method to draw object. You can rely on position and size here.
	void drawSelf(){
		switch (type){
			case 1: {GUI::DrawSunkenPane(position, position+size); break;}
			case 2: {GUI::DrawPane(position, position+size); break; }
			case 3: {GUI::DrawFramedPane(position, position+size); break;}
			default: {GUI::DrawWindow(position, position+size); break;}
		}
		GenericGUIItem::drawSelf();
	}

}

class List : GenericGUIItem{
	Rectangle@ anchor = @Rectangle(Vec2f(0,0),Vec2f(0,0),SColor(255,64,64,64));
	Label@[] items;
	Label@ current = @Label(Vec2f(6,8),Vec2f(30,10),"",SColor(255,0,0,0),false);
	bool open = false;
	int timeOut;

	List(Vec2f _position,Vec2f _size, string _name = ""){
		super(_position,_size);
		name = _name;
		DebugColor = SColor(155,23,162,23);
		addChild(current);
	}

	void setCurrentItem(string _item){
		current.setText(_item);
	}

	void addItem(string _item){
		Vec2f textSize;
		GUI::GetTextDimensions(_item, textSize);
		Label@ temp = @Label(Vec2f(0,0),textSize,_item,SColor(255,255,255,255),false);
		if (textSize.x > anchor.size.x){ anchor.size = Vec2f(textSize.x*1.5f,anchor.size.y + textSize.y + 4);}
		else{ anchor.size = Vec2f(anchor.size.x*1.5f,anchor.size.y + textSize.y + 4);}
		items.push_back(temp);
	}

	void resetList(){
		for(int i = items.length-1; i >= 0; i--){
			print("reset: "+i);
			items.removeAt(i);
		}
		anchor.size = Vec2f(0,0);
	}

	void drawSelf(){
		GUI::DrawButtonPressed(position, position+size);
		anchor.position = position +Vec2f(0,size.y);
		if (open) {
			anchor.draw();
			for(int i = 0; i < items.length; i++){
				items[i].position = anchor.position + Vec2f(0,(20*i));
				items[i].draw();
				if (items[i].isClickedWithLButton){ 
					current.setText(items[i].label);
					open = false;
				}
			}
		}
		if (timeOut > 5) {open = false;timeOut = 0;}
		if (!anchor.isHovered && !isHovered && open)timeOut++;
		GenericGUIItem::drawSelf();
	}
}

class Button : GenericGUIItem{
	string desc;
	SColor color;
	bool selfLabeled = false;
	bool toggled = false;

	Button(Vec2f _position,Vec2f _size){
		super(_position,_size);
		DebugColor = SColor(155,255,233,0);
	}

	//Use to automatically make a centered label on the button using text from _desc
	Button(Vec2f _position,Vec2f _size, string _desc, SColor _color){
		super(_position,_size);
		desc = _desc;
		color = _color;
		selfLabeled = true;
		DebugColor = SColor(155,255,233,0);
	}

	void drawSelf(){
		//Logic to change button based on state
		if(isClickedWithLButton || isClickedWithRButton || toggled){
			GUI::DrawButtonPressed(position, position+size);	
		} else if(isHovered && !_isLocked){
			GUI::DrawButtonHover(position, position+size);
		} else {
			GUI::DrawButton(position, position+size);	
		}
		if (selfLabeled){
			drawRulesFont(desc,color,position + Vec2f(.5,.5),position + size - Vec2f(.5,.5),true,true);
		}
		if(_isLocked)GUI::DrawRectangle(position, position+size,SColor(200,64,64,64));
		GenericGUIItem::drawSelf();
	}

}

class ScrollBar : GenericGUIItem{
	float secSize, offset;
	int sections, value;
	bool horizontal;
	

	ScrollBar(Vec2f _position, int _length, int _sections, bool _hort = false, int _val = 0){
		if (_hort){
			super(_position,Vec2f(_length, 20));
			secSize = size.x/_sections;
			offset =  (secSize * _val) -5;
		} else {
			super(_position,Vec2f(20, _length));
			secSize = size.y/_sections;
			offset =  (secSize * _val) -5;
		}
		sections = _sections;
		horizontal = _hort;
		value = _val;
		DebugColor = SColor(155,255,106,0);
	}

	void updateValues(){
		value = ((offset+5)/secSize);
	}

	Vec2f getSliderPos(){
		return Vec2f(offset+position.x,offset+position.y);
	}

	void slide(){
		float slideAmt;
		if (horizontal){
			if(_SlideStartPosition.x >= _startSlidePos.x && _SlideStartPosition.x <= _startSlidePos.x + 10){
				if(_SlideCurrentPosition.x > _SlideStartPosition.x){slideAmt = _startSlidePos.x + (_SlideCurrentPosition.x - _SlideStartPosition.x);}
				if(_SlideCurrentPosition.x <= _SlideStartPosition.x){slideAmt = _startSlidePos.x - (_SlideStartPosition.x - _SlideCurrentPosition.x);}
			}else{
				slideAmt = _SlideStartPosition.x;
			}
			if(slideAmt < position.x){slideAmt = position.x;}
			if(slideAmt + 10 > position.x + size.x){slideAmt = position.x+size.x-10;}
			slideAmt -= position.x;	
		} else{
			if(_SlideStartPosition.y >= _startSlidePos.y && _SlideStartPosition.y <= _startSlidePos.y + 10){
				if(_SlideCurrentPosition.y > _SlideStartPosition.y){slideAmt = _startSlidePos.y + (_SlideCurrentPosition.y - _SlideStartPosition.y);}
				if(_SlideCurrentPosition.y <= _SlideStartPosition.y){slideAmt = _startSlidePos.y - (_SlideStartPosition.y - _SlideCurrentPosition.y);}
			}else{
				slideAmt = _SlideStartPosition.y;
			}

			if(slideAmt < position.y){slideAmt = position.y;}
			if(slideAmt + 10 > position.y + size.y){slideAmt = position.y+size.y-10;}
			slideAmt -= position.y;	
		}
		offset = slideAmt;
		updateValues();
	}

	void drawSelf(){
		GUI::DrawSunkenPane(position, position+size);
		if (horizontal){
			GUI::DrawButton(position + Vec2f(offset,-3),position + Vec2f(offset,-3)+Vec2f(10,26));
		} else {
			GUI::DrawButton(position + Vec2f(-3,offset)+Vec2f(26,10),position + Vec2f(-3,offset));
		}
		
	}
}

class ProgressBar : GenericGUIItem{
	
	float val;
	SColor color;
	bool colored = false;
	bool inversed = false;

	ProgressBar(Vec2f _position,Vec2f _size, float _initVal){
		super(_position,_size);
		val = _initVal;
	}

	ProgressBar(Vec2f _position,Vec2f _size, float _initVal, SColor _color, bool _inversed){
		super(_position,_size);
		val = _initVal;
		color = _color;
		colored = true;
		inversed = _inversed;
		// if inversed, bar fills from right to left, if not then fills normally (left to right)
	}

	void drawSelf(){
		if (colored){
			if (inversed){
				GUI::DrawRectangle(position, position+size);
				GUI::DrawRectangle((position+size)-Vec2f(size.x*val,size.y), position+size,color);
			}
			else{
				GUI::DrawRectangle(position, position+size);
				GUI::DrawRectangle(position, position+Vec2f(size.x*val,size.y),color);
			}
		}
		else GUI::DrawProgressBar(position, position+size, val);
		GenericGUIItem::drawSelf();
	}

	float findVal(int currentVal, int maxVal){
		return (1.0f*Maths::Abs(currentVal))/maxVal;
	}

	void setVal(float _val){
		val = _val;
	}

}

class TextureBar : GenericGUIItem{
	
	float val = 10.0f,max,increment,scale,team = 0;
	string name, bar, back;
	Vec2f barSize, backSize;
	int barStart, backStart;

	TextureBar(Vec2f _position,float _Val,string _bar,Vec2f _barSize,int barFrame,string _back, Vec2f _backSize, int backFrame,float _scale = 1.0f,float _increment = 0.5f ){
		super(_position,Vec2f((_backSize.x*_scale*2*(_Val/_increment)+(8*_scale)),(_backSize.y*_scale*2)));
		max = _Val;
		increment = _increment;
		scale = _scale;
		bar = _bar;
		back = _back;
		barSize = _barSize;
		backSize = _backSize;
		barStart = barFrame;
		backStart = backFrame;
		DebugColor = SColor(155,86,35,175);
	}

	void drawSelf(){
		int frame1 = backStart+1,frame2,counter = 0;
		float s =(backSize.x*scale)*2;
		Vec2f offset = Vec2f(position.x+(8*scale),position.y);
		GUI::DrawIcon(back,backStart,backSize,position,scale);
		string dataDump = "Dump data:";
		for (f32 i = 0.0f; i < max; i += increment)
		{
			GUI::DrawIcon(back,frame1,backSize,offset+Vec2f(s*counter,0),scale);

			float check = val - i;
			if (check > 0){
				if (check <= 0.125f) { frame2 = barStart + 3; } 
           	 	else if (check <= 0.25f) { frame2 = barStart + 2; } 
            	else if (check <= 0.375f) { frame2 = barStart + 1; } 
				else if (check > 0.375f) { frame2 = barStart; } 
           		else { frame2 = barStart + 4; }
      	    } else { frame2 = barStart + 4; }
      	    dataDump += (" I "+i+"="+check);
      	    GUI::DrawIcon(bar,frame2,barSize,Vec2f(position.x+(5*scale)+(s*counter),position.y),scale,team); 
			counter++;
		}
		GUI::DrawIcon(back,backStart+2,backSize,offset+Vec2f(s*counter,0),scale);
		//print(dataDump);
		GenericGUIItem::drawSelf();
	}

	float findVal(int currentVal, int maxVal){
		return (1.0f*Maths::Abs(currentVal))/maxVal;
	}

	void setVal(float _val){
		val = _val;
	}

}

class Rectangle : GenericGUIItem{
	
	bool useColor = false;
	SColor color;

	Rectangle(Vec2f _position,Vec2f _size, SColor _color){
		super(_position,_size);
		color = _color;
		useColor = true;
		DebugColor = SColor(155,255,255,255);
	}

	Rectangle(Vec2f _position,Vec2f _size ){
		super(_position,_size);
		DebugColor = SColor(155,255,255,255);
	}

	void drawSelf(){
		if(useColor)
			GUI::DrawRectangle(position, position+size,color);
		else
			GUI::DrawRectangle(position, position+size);
		GenericGUIItem::drawSelf();
	}

}

class GUIContainer : GenericGUIItem{
	
	GUIContainer(Vec2f _position, Vec2f  _size){
		super(_position,_size);
		DebugColor = SColor(155,0,194,155);
	}

	void drawSelf(){
		GenericGUIItem::drawSelf();
	}

}



class Bubble : GenericGUIItem{
	
	Bubble(Vec2f _position,Vec2f _size){
		super(_position,_size);
	}

	void drawSelf(){
		GUI::DrawBubble(position, position+size);
		GenericGUIItem::drawSelf();
	}

}

class Line : GenericGUIItem{
	
	SColor color;

	Line(Vec2f _position,Vec2f _size, SColor _color){
		super(_position,_size);
		color = _color;
	}

	void drawSelf(){
		GUI::DrawLine2D(position, position+size, color);
		GenericGUIItem::drawSelf();
	}

}

class Label : GenericGUIItem{
	
	string label;
	SColor color;
	bool centered;
	Label(Vec2f _position,Vec2f _size,string _label,SColor _color,bool _centered){
		super(_position,_size);
		label = _label;
		color = _color;
		centered = _centered; //center text to middle of label
		DebugColor = SColor(155,0,76,7);
	}

	void drawSelf(){
		drawRulesFont(label,color,position,position+size,centered,centered);
		GenericGUIItem::drawSelf();
	}

	void setText(string _label){
		label = _label;
	}

}


class Icon : GenericGUIItem{
	
	string name;
	float scale = 1;
	int team = 0, index, animCurrent = 0;
	bool animate = false;
	Vec2f iSize;
	Anim[] animList;


	//Static Icon setup
	Icon(string _name, Vec2f _position,Vec2f _size,int _index,float _scale){
		super(_position,_size*_scale*2);
		name = _name;	
		scale = _scale;
		iSize = _size;
		index = _index;
		DebugColor = SColor(155,13,0,158);
	}

	//Animated Icon setup
	Icon(Vec2f _position,string _name, float _scale){
		super(_position,Vec2f(0,0));
		/*_frame = 0;
		_animFreq = animFreq;
		_iDimension = iDimension;
		_image = image;*/
		name = _name;	
		scale = _scale;
		animate = true;
		DebugColor = SColor(155,31,105,158);
	}

	void addAnim(Anim a){ //Add an Animation
		animList.push_back(a);
	}

	void setAnim(int a){
		animCurrent = a;
		size = animList[a].iDim*scale*2;
	}

	void setFrame(int a){
		animList[animCurrent].frame = a;
	}

	void drawSelf() override {
		if (animate){
			//updateAnimationState();
			animList[animCurrent].drawAnim(position,scale,team);
		}
		else {
			GUI::DrawIcon(name,index,iSize,position,scale,team);
			GenericGUIItem::drawSelf();
		}	
	}
}

class Anim{
	int[] index;
	int frame,freq;
	string name, image;
	Vec2f iDim;

	Anim(string _name, string _image,Vec2f _iDim, int f){
		name = _name;
		image = _image;
		freq = f;
		iDim = _iDim;
		frame = 0;
	}

	//Animation frame updating logic
	void updateAnimationState(){
		if (freq == 0) return;
		if(getGameTime() % freq == 0)
		{
			frame = frame + 1;
			if (frame >= index.length) frame=0;
		}
	}	

	void drawAnim(Vec2f position, float scale,int team){
		updateAnimationState();
		GUI::DrawIcon(image,index[frame],iDim,position,scale,team);
	}

	void addFrame(int frames){ //Add single frame
		index.push_back(frames);
	}

	void addFrame(int[] frames){ //Add frames from an int[]
		for(int i = 0; i <frames.length; i++){
			index.push_back(frames[i]);
		}

	}

	void addFrame(int start, int end){ //Add frames from a start to end
		if (start < end){
			for(int i = start; i <= end; i++){
				index.push_back(i);
			}
		}
		else {
			for(int i = start; i > end; i--){
				index.push_back(i);
			}
		}

	}

	void setFrame(int _frame){
		frame = _frame;
	}

}
