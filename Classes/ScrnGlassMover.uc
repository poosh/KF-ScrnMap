class ScrnGlassMover extends KFGlassMover;

var ScrnGlassRepl MyRepl;
var int MyIndex;

function PostBeginPlay()
{
    local ScrnGlassRepl Repl;
    local string s;
    local int GlassOffset;

    s = string(Name);
    if (Left(s, 14) == "ScrnGlassMover") {
        MyIndex = int(Mid(s, 14));
    }
    GlassOffset = MyIndex >> 7;  // ScrnGlassRepl.OFFSET_BITS
    // log(Name $ " MyIndex=" $ MyIndex $ " GlassOffset=" $ GlassOffset);
    foreach DynamicActors(class'ScrnGlassRepl', Repl) {
        if (Repl.GlassOffset == GlassOffset)
            break;
    }

    if (Repl == none || Repl.GlassOffset != GlassOffset) {
        Repl = spawn(class'ScrnGlassRepl');
        Repl.GlassOffset = GlassOffset;
    }
    MyRepl = Repl;

    super.PostBeginPlay();
}

simulated function CrackWindow()
{
    bCracked = true;
    if (Level.NetMode != NM_DedicatedServer) {
        Skins.Length = Max(1,Skins.Length);
        Skins[0] = ShatteredTexture;
    }
    if (MyRepl != none) {
        MyRepl.ServerSend(self);
    }
}

simulated function BreakWindow()
{
    SetCollision(false,false,false);
    bHidden = true;
    if (Level.NetMode!=NM_DedicatedServer) {
        Spawn(BreakGlassBits);
    }
    if (MyRepl != none) {
        MyRepl.ServerSend(self);
    }
}


defaultproperties
{
    bAlwaysRelevant=False
    RemoteRole=ROLE_None
}