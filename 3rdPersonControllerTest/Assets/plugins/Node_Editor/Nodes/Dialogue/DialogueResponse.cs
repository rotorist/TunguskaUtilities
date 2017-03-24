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
	[Node (false, "Dialogue/Dialogue Response")]
	public class DialogueResponse : Node 
	{
		public const string ID = "dialogueResponse";
		public override string GetID { get { return ID; } }

		public string ResponseText = "";
		public string EventID = "";


		public override Node Create (Vector2 pos) 
		{
			DialogueResponse node = CreateInstance<DialogueResponse> ();
			node.rect = new Rect (pos.x, pos.y, 150, 100);
			node.name = "Response";

			node.CreateInput ("Condition", "Float");


			return node;
		}

		protected internal override void NodeGUI () 
		{

			GUILayout.BeginHorizontal ();
			GUILayout.BeginVertical ();

			GUILayout.TextArea (EventID);

			if(GUILayout.Button("Add Input"))
			{
				this.CreateInput("", "Flow");
			}



			for(int i=0; i<Inputs.Count; i++)
			{
				Inputs [i].DisplayLayout ();
			}


			GUILayout.EndVertical ();
			GUILayout.BeginVertical ();



			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();

			GUIContent content = new GUIContent(ResponseText);
			GUILayout.TextArea (ResponseText);
			float height = GUI.skin.textArea.CalcHeight(content, 140);
			if(this.rect != null)
			{
				this.rect.height = height + 70 + 18 * Inputs.Count;
			}

		}

		public override string GetXML () 
		{

			return "";
		}
	}
}