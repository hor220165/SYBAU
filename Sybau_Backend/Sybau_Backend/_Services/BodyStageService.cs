using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class BodyStageService
{
    public BodyStage GetBodyStage(int lvl)
    {
        if (lvl >= 70)
            return BodyStage.Bodybuilder;
        if (lvl >= 20)
            return BodyStage.Defined;

        return BodyStage.Skinny;
    }
}