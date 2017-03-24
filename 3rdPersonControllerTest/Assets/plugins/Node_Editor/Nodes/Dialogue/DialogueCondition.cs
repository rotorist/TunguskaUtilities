using UnityEngine;
using NodeEditorFramework;
using NodeEditorFramework.Utilities;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using System.Text;
using System.Xml;
using System.IO;
using System;



namespace NodeEditorFramework.Standard
{
	[Node (false, "Dialogue/Dialogue Condition")]
	public class DialogueCondition : Node 
	{
		public enum OpType { EqualTo, GreaterThan, LessThan, GreaterEq, LessEq, NotEq }

		public const string ID = "dialogueCondition";
		public override string GetID { get { return ID; } }

		public string ConditionName;
		public string StoryConditionName;
		public string CompareValue;
		public OpType Operation;

		public override Node Create (Vector2 pos) 
		{
			DialogueCondition node = CreateInstance<DialogueCondition> ();

			node.rect = new Rect (pos.x, pos.y, 150, 60);
			node.name = "Condition";

			node.CreateOutput ("If True", "Float");


			return node;
		}

		protected internal override void NodeGUI () 
		{
			GUILayout.Label (ConditionName);

			GUILayout.BeginHorizontal ();
			GUILayout.BeginVertical ();

			GUILayout.EndVertical ();
			GUILayout.BeginVertical ();

			Outputs [0].name = "If " + Operation + " " + CompareValue;
			Outputs [0].DisplayLayout ();

			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();


		}

		public override string GetXML () 
		{

			return "";
		}

		public int ConvertOpToInt(OpType type)
		{
			switch(type)
			{
			case OpType.LessThan: return -2; break;
			case OpType.LessEq: return -1; break;
			case OpType.EqualTo: return 0; break;
			case OpType.GreaterEq: return 1; break;
			case OpType.GreaterThan: return 2; break;
			case OpType.NotEq: return -3; break;
			}

			return 0;
		}
	}
}