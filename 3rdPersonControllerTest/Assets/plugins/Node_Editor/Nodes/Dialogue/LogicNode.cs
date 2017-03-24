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
	[Node (false, "Dialogue/Logic")]
	public class LogicNode : Node 
	{
		public enum LogicOpType { And, Or }

		public const string ID = "logicNode";
		public override string GetID { get { return ID; } }

		public LogicOpType Operation;

		public override Node Create (Vector2 pos) 
		{
			LogicNode node = CreateInstance<LogicNode> ();

			node.rect = new Rect (pos.x, pos.y, 80, 60);
			node.name = "Logic";

			node.CreateInput ("", "Float");
			node.CreateOutput ("", "Float");


			return node;
		}

		protected internal override void NodeGUI () 
		{

			GUILayout.BeginHorizontal ();
			GUILayout.BeginVertical ();

			if(GUILayout.Button("Add"))
			{
				this.CreateInput("", "Float");
			}

			for(int i=0; i<Inputs.Count; i++)
			{
				Inputs [i].DisplayLayout ();
			}

			GUILayout.EndVertical ();
			GUILayout.BeginVertical ();

			Outputs [0].name = Operation.ToString();
			Outputs [0].DisplayLayout ();

			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();
			if(this.rect != null)
			{
				this.rect.height = 40 + 18 * Inputs.Count;
			}
		}

		public override string GetXML () 
		{
			
			return "";
		}
	}
}