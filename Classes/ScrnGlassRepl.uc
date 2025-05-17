class ScrnGlassRepl extends ReplicationInfo;

const OFFSET_BITS = 7;
const MAX_GLASSES = 128;
const MAX_BITS = 256;

var int GlassMask[8];  // up to 256 bits. Two bits per glass. 128 glasses.
var transient int ClientGlassMask[8];
var int GlassOffset;
var transient bool bBegunNetPlay;

replication
{
    reliable if (bNetInitial && Role == Role_Authority)
        GlassOffset;
    reliable if ((bNetDirty || bNetInitial) && Role == Role_Authority)
        GlassMask;
}

simulated function PostNetBeginPlay()
{
    CheckGlass();
    bBegunNetPlay = true;
}

simulated function PostNetreceive()
{
    CheckGlass();
}

function ServerSend(ScrnGlassMover Glass)
{
    local int index, i, val;

    index = Glass.MyIndex - (GlassOffset << OFFSET_BITS);
    if (index < 0 || index >= MAX_GLASSES) {
        warn(Glass.name $ " called wrong replicator " $ name $ " (GlassOffset="$GlassOffset$")");
        return;
    }
    index *= 2; // 2 bytes per index
    val = (int(Glass.bHidden) << 1) | int(Glass.bCracked);
    i = index >> 5;
    index = index & 31;
    if (((GlassMask[i] >> index) & 3) == val) {
        // log(Glass.name $ " - state doesn't change " $ val);
        return;
    }
    GlassMask[i] = GlassMask[i] & (~(3 << index));
    GlassMask[i] = GlassMask[i] | (val << index);
    // log(Glass.name $ " - state " $ val $ " GlassOffset="$GlassOffset$" mask["$i$"]=" $ GlassMask[i]);
    NetUpdateTime = Level.TimeSeconds - 1;
}

simulated function CheckGlass()
{
    local int i, j, diff;

    for (i = 0; i < ArrayCount(GlassMask); ++i) {
        diff = GlassMask[i] ^ ClientGlassMask[i];
        if (diff == 0)
            continue;

        for (j = 0; diff != 0 && j < 16; j += 1) {
            if ((diff & 3) != 0) {
                ProcessWindow((GlassOffset << OFFSET_BITS) + (i << 4) + j, bool((diff >> 1) & 1), bool(diff & 1));
            }
            diff = diff >>> 2;
        }
        ClientGlassMask[i] = GlassMask[i];
    }
}

simulated function ProcessWindow(int index, bool bHide, bool bCrack)
{
    local string sname;
    local ScrnGlassMover Glass, G;

    sname = "ScrnGlassMover" $ index;
    // log("ProcessWindow " $ sname $ " Hide="$bHide $ " Crack="$bCrack);
    foreach DynamicActors(class'ScrnGlassMover', G) {
        if (String(G.Name) ~= sname) {
            Glass = G;
            break;
        }
    }
    if (Glass == none) {
        log(sname $ " not found");
        return;
    }

    if (bHide) {
        // We can check for bBegunNetPlay to avoid shattering previously broken glass for late joiners.
        // However, those effects are too cool to be removed.
        Glass.bHidden = true;
        Glass.BreakWindow();
    }
    else if (bCrack) {
        Glass.CrackWindow();
    }
}


defaultproperties
{
    bNetNotify=true
}