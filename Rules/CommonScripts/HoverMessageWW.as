
shared class HoverMessageWW
{
    int quantity;
	string prefix;
    string name;
    uint ticker;
    f32 ypos;
    f32 xpos;
    uint ttl;
    uint fade_ratio;
	SColor color;

    HoverMessageWW() {} // required for handles to work

    HoverMessageWW( string _name, int _quantity, SColor _color = color_white, uint _ttl = 75, uint _fade_ratio = 2, bool singularise = true, string _prefix = "") 
	{
        if (_quantity >= 0 &&_quantity < 2 && singularise) 
		{
            _name = this.singularize(_name);
        }

		prefix = _prefix;
        name = _name;
        quantity = _quantity;
        ticker = 0;
        ypos = 0.0;
        xpos = 0.0;
        ttl = _ttl;
        fade_ratio = _fade_ratio;
		color = _color;
    }

    // draw the text
    void draw(Vec2f pos) 
	{
        string m = this.message();
        SColor color = this.getColor();
        GUI::DrawText(m, pos, color);
    }
	
    void drawDeltaBooty(CBlob@ blob) 
	{
        string m = this.message();
		const int slotsSize = 6;
        Vec2f pos = Vec2f( 158 , 11);
        SColor color = this.getColor();
        GUI::DrawText(m,pos,color);
    }

    // get message into a nice, friendly format
    string message() {
        string d = "" + prefix + quantity + " " + name;
        return d;
    }

    // see if this message is expired, or should be removed from GUI
    bool isExpired() 
	{
        ticker = ticker + 1;
        return ticker > ttl;
    }
	
	int ticksSinceCreated()
	{
		return ticker;
	}

    // get the active color of the message. decrease proportionally by the fadeout ratio
    private SColor getColor() {
        uint alpha = Maths::Max(0, 255-(ticker*fade_ratio));
        SColor color2 = SColor(alpha, color.getRed(),color.getGreen(),color.getBlue());
        return color2;
    }

    // get the position of the message. Store it to the object if no pos is already set. This allows us to do the
    // hovering above where it was picked effect. Finally, slowly make it rise by decreasing by a multiple of the ticker
    private Vec2f getPos(CBlob@ blob,string m) 
	{
        if (ypos == 0.0) 
		{
            Vec2f pos2d = blob.getScreenPos();
            int top = pos2d.y - 2.5f*blob.getHeight() - 20.0f;
            int margin = 4;
            Vec2f dim;
            GUI::GetTextDimensions( m , dim );
            dim.x = Maths::Min( dim.x, 200.0f );
            dim.x += margin;
            dim.y += margin;
            dim.y /= 3.8f;
            ypos = pos2d.x-dim.x/2;
            xpos = top - 2*dim.y;
        }

        xpos = xpos - (ticker / (40));
        Vec2f pos(ypos, xpos);
        return pos;
    }

    // Singularize, or de-pluralize, a string
    private string singularize(string str) {
        uint len = str.length();
        string lastChar = str.substr(len-1);

        if (lastChar == "s") {
            str = str.substr(0,len-1);
        }

        return str;
    }
};
