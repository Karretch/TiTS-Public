package classes.GameData.Pregnancy.Handlers 
{
	/**
	 * ...
	 * @author Karretch, based on Savin's originals
	 */
	import classes.GameData.Pregnancy.BasePregnancyHandler;
	import classes.Creature;
	import classes.PregnancyData;
	import classes.kGAMECLASS;
	import classes.GameData.StatTracking;
	import classes.GLOBAL;
	import classes.StorageClass;
	import classes.Engine.Utility.rand;
	import classes.Engine.Interfaces.ParseText;
	import classes.GameData.ChildManager;
	import classes.GameData.Pregnancy.Child;
	import classes.GameData.Pregnancy.UniqueChild;
	import classes.GameData.Pregnancy.Templates.IlariaUniqueChild;
	import classes.Characters.PlayerCharacter;
	import classes.Engine.Interfaces.AddLogEvent;
	 
	public class IlariaPregnancyHandler extends BasePregnancyHandler
	{
		
		public function IlariaPregnancyHandler() 
		{
			_handlesType = "IlariaPregnancy";
			_basePregnancyIncubationTime = (60 * 24 * 210); // 7 Months
			_basePregnancyChance = 0.1;
			_alwaysImpregnate = false;
			_ignoreInfertility = false;
			_ignoreFatherInfertility = false;
			_ignoreMotherInfertility = false;
			_allowMultiplePregnancies = true;
			_canImpregnateButt = false;
			_canImpregnateVagina = true;
			_canFertilizeEggs = false;
			_pregnancyQuantityMinimum = 2;
			_pregnancyQuantityMaximum = 6;
			_definedAverageLoadSize = 50000;  //Assume this is character cum output, Ilaria locked at this
			_pregnancyChildType = GLOBAL.CHILD_TYPE_LIVE;
			_pregnancyChildRace = GLOBAL.TYPE_CANINE
			_childMaturationMultiplier = 1.0;
			
			_onSuccessfulImpregnation = ilariaSuccessfulImpregnation;
			_onDurationEnd = ilariaOnDurationEnd;
		
			//Progression blurbs
			//To be written
			//Morning sickness
			addStageProgression(_basePregnancyIncubationTime - (30 * 24 * 60), function(pregSlot:int):void {
				AddLogEvent(ParseText("Yo, you're sick for some reason"), "passive");
			}, true);
			//Codex check
			addStageProgression(_basePregnancyIncubationTime - (45 * 24 * 60), function(pregSlot:int):void {
				AddLogEvent(ParseText("Yo, sick too often, you's preggo"), "passive");
				kGAMECLASS.pc.bellyRatingMod += 5;
				var pData:PregnancyData = kGAMECLASS.pc.pregnancyData[pregSlot];
				pData.pregnancyBellyRatingContribution += 5;
			}, true);
			//Visibly obviously pregnant
			addStageProgression(_basePregnancyIncubationTime - (100 * 24 * 60), function(pregSlot:int):void {
				var textBuff:String = "You belly showin you ."
				AddLogEvent(ParseText(textBuff), "passive");
				kGAMECLASS.pc.bellyRatingMod += 10;
				var pData:PregnancyData = kGAMECLASS.pc.pregnancyData[pregSlot];
				pData.pregnancyBellyRatingContribution += 10;
			}, true);
			//Belly too big, start lactatin
			addStageProgression(_basePregnancyIncubationTime - (130 * 24 * 60), function(pregSlot:int):void {
				var textBuff:String = ParseText("You belly too big.");
				if(!kGAMECLASS.pc.canLactate()) 
				{
					textBuff += ParseText(" You done got milk");
					if(kGAMECLASS.pc.milkMultiplier < 100) kGAMECLASS.pc.milkMultiplier = 100;
					kGAMECLASS.pc.milkFullness += 20;
				}
				AddLogEvent(textBuff, "passive");
				kGAMECLASS.pc.bellyRatingMod += 10;
				var pData:PregnancyData = kGAMECLASS.pc.pregnancyData[pregSlot];
				pData.pregnancyBellyRatingContribution += 10;
			}, true);
			// kicking often, milk flows free, you're about ready to pop
			//Straight copy/pasted from korg - rewrite
			addStageProgression(_basePregnancyIncubationTime - (200 * 24 * 60), function(pregSlot:int):void {
				var textBuff:String = "Your ";
				if(kGAMECLASS.pc.canLactate()) 
				{
					textBuff += "nipples leak milk ";
					if(!kGAMECLASS.pc.isChestExposed()) textBuff += "into your [pc.upperGarment] ";
					textBuff += "constantly and your ";
				}
				textBuff += "[pc.belly] is further stretched than the pregnancy handbooks say possible. If you get any more swollen, you’re not going to be able to move. When will the babies come?";
				AddLogEvent(ParseText(textBuff), "passive");
				kGAMECLASS.pc.bellyRatingMod += 10;
				var pData:PregnancyData = kGAMECLASS.pc.pregnancyData[pregSlot];
				pData.pregnancyBellyRatingContribution += 10;
			}, true);
		}
		public static function ilariaSuccessfulImpregnation(father:Creature, mother:Creature, pregSlot:int, thisPtr:BasePregnancyHandler):void
		{
			BasePregnancyHandler.defaultOnSuccessfulImpregnation(father, mother, pregSlot, thisPtr);
			
			var pData:PregnancyData = mother.pregnancyData[pregSlot] as PregnancyData;
			
			// Always start with the minimum amount of children.
			var quantity:int = thisPtr.pregnancyQuantityMinimum;
			
			// Unnaturally fertile mothers may get multiple children.
			for(var i:Number = mother.fertility(); i >= 1.5; i -= 0.5)
			{
				quantity += rand(thisPtr.pregnancyQuantityMaximum + 1);
			}
			if (quantity > thisPtr.pregnancyQuantityMaximum) quantity = thisPtr.pregnancyQuantityMaximum;
			
			// Add extra bonuses.
			var fatherBonus:int = Math.round((father.cumQ() * 2) / thisPtr.definedAverageLoadSize);
			var motherBonus:int = Math.round((quantity * mother.pregnancyMultiplier()) - quantity);
			quantity += fatherBonus + motherBonus;
			
			// Cap at 3x the maximum!
			var quantityMax:int = Math.round(thisPtr.pregnancyQuantityMaximum * 3.0);
			if (quantity > quantityMax) quantity = quantityMax;
			
			pData.pregnancyQuantity = quantity;
		}
		public static function ilariaOnDurationEnd(mother:Creature, pregSlot:int, thisPtr:BasePregnancyHandler):void
		{
			var pData:PregnancyData = mother.pregnancyData[pregSlot];
			
			//If this is the first birth, go at it.
			if (!mother.hasStatusEffect("Ilaria Pregnancy Ends") && !kGAMECLASS.disableExploreEvents())
			{
				// Baby count check (just in case)
				var babies:int = mother.pregnancyData[pregSlot].pregnancyQuantity;
				var belly:int = mother.pregnancyData[pregSlot].pregnancyBellyRatingContribution;
				
				// Generate babies
				var c:Child = Child.NewChildWeights(
					thisPtr.pregnancyChildRace,
					thisPtr.childMaturationMultiplier,
					babies,
					thisPtr.childGenderWeights
				);
				
				var babyList:Array = (new IlariaPregnancyHandler()).ilariaChildren(mother, babies);
				var genderList:Array = [];
				var i:int = 0;
				var j:int = 0;
				for(i = 0; i < babyList.length; i++)
				{
					//for(j = 0; j < babyList[i].NumNeuter; j++) { genderList.push(-1); }
					for(j = 0; j < babyList[i].NumFemale; j++) { genderList.push(0); }
					for(j = 0; j < babyList[i].NumMale; j++) { genderList.push(1); }
					//for(j = 0; j < babyList[i].NumIntersex; j++) { genderList.push(2); }
					ChildManager.addChild(babyList[i]);
				}
				// Random baby's gender ( 1 for male, 0 for female )
				var babyGender:int = rand(2);
				if(genderList.length > 0) babyGender = genderList[rand(genderList.length)];

				mother.createStatusEffect("Ilaria Pregnancy Ends", babies, belly, pregSlot, babyGender, true);
				kGAMECLASS.eventQueue.push(kGAMECLASS.ilariaPregnancyEnds);
				IlariaPregnancyHandler.ilariaCleanupData(mother, pregSlot, thisPtr);
			}
			//Delay subsequent births till the first has had time to go off.
			else mother.pregnancyData[pregSlot].pregnancyIncubation += 24;
		}
		public static function ilariaCleanupData(mother:Creature, pregSlot:int, thisPtr:BasePregnancyHandler):void
		{
			var pData:PregnancyData = mother.pregnancyData[pregSlot] as PregnancyData;
			
			mother.bellyRatingMod -= pData.pregnancyBellyRatingContribution;
			
			StatTracking.track("pregnancy/ilaria ", pData.pregnancyQuantity);
			StatTracking.track("pregnancy/total births", pData.pregnancyQuantity);
			StatTracking.track("pregnancy/total day care", pData.pregnancyQuantity);
			
			pData.reset();
		}
		override public function nurseryEndPregnancy (mother:Creature, pregSlot:int, useBornTimestamp:uint):Child
		{
			var pData:PregnancyData = mother.pregnancyData[pregSlot] as PregnancyData;
			
			var babyList:Array = ilariaChildren(mother, pData.pregnancyQuantity);
			var i:int = 0;
			for(i = 0; i < babyList.length; i++)
			{
				babyList[i].BornTimestamp = useBornTimestamp;
				ChildManager.addChild(babyList[i]);
			}
			
			mother.bellyRatingMod -= pData.pregnancyBellyRatingContribution;
			
			StatTracking.track("pregnancy/ilaria ", pData.pregnancyQuantity);
			StatTracking.track("pregnancy/total births", pData.pregnancyQuantity);
			StatTracking.track("pregnancy/total day care", pData.pregnancyQuantity);
			
			pData.reset();
			
			if(babyList.length > 0)
			{
				var cTemp:Child = new Child();
				cTemp.RaceType = babyList[0].RaceType;
				cTemp.MaturationRate = babyList[0].MaturationRate;
				cTemp.BornTimestamp = babyList[0].BornTimestamp;
				cTemp.NumMale = 0;
				cTemp.NumFemale = 0;
				for(i = 0; i < babyList.length; i++)
				{
					cTemp.NumMale += babyList[i].NumMale;
					cTemp.NumFemale += babyList[i].NumFemale;
				}
				return cTemp;
			}
			return null;
		}		
		private function ilariaChildren(mother:Creature, numKids:int = 0):Array
		{
			var babyList:Array = [];
			
			var traitChar:Creature = mother;
			if(mother is PlayerCharacter) traitChar = kGAMECLASS.chars["PC_BABY"];
			
			for(var i:int = 0; i < numKids; i++)
			{
				var c:UniqueChild = new IlariaUniqueChild();
				
				c.RaceType = pregnancyChildRace;
				// 50% Male or Female
				if(rand(2) == 0) { c.NumMale = 1; c.NumFemale = 0; c.NumIntersex = 0; c.NumNeuter = 0; }
				else { c.NumMale = 0; c.NumFemale = 1; c.NumIntersex = 0; c.NumNeuter = 0; }
				
				// Race modifier (if different races)
				c.originalRace = c.hybridizeRace(mother.originalRace, c.originalRace, ((mother is PlayerCharacter) ? true : false));
				
				// Adopt mother's colors at random (if applicable):
				if(rand(2) == 0) c.skinTone = traitChar.skinTone;
				if(rand(2) == 0) c.lipColor = traitChar.lipColor;
				if(rand(2) == 0) c.nippleColor = traitChar.nippleColor;
				if(rand(2) == 0) c.eyeColor = traitChar.eyeColor;
				if(traitChar.hairColor != "NOT SET" && rand(2) == 0) c.hairColor = traitChar.hairColor;
				if(traitChar.furColor != "NOT SET" && rand(2) == 0) c.furColor = traitChar.furColor;
				//if(rand(2) == 0) c.scaleColor = traitChar.scaleColor;
				//if(rand(2) == 0) c.chitinColor = traitChar.scaleColor;
				//if(rand(2) == 0) c.featherColor = traitChar.furColor;
				
				c.MaturationRate = childMaturationMultiplier;
				c.BornTimestamp = kGAMECLASS.GetGameTimestamp();
				
				babyList.push(c);
			}			
			return babyList;
		}
	}
}
