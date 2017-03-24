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
	[Node (false, "Dialogue/Dialogue Option")]
	public class DialogueOption : Node 
	{
		public const string ID = "dialogueOption";
		public override string GetID { get { return ID; } }

		public string Title = "";
		public string Text = "";

		public override Node Create (Vector2 pos) 
		{
			DialogueOption node = CreateInstance<DialogueOption> ();

			node.rect = new Rect (pos.x, pos.y, 150, 75);
			node.name = "Dialogue Option";

			node.CreateInput ("Condition", "Float");
			node.CreateOutput ("Next Node", "Flow");

			return node;
		}

		protected internal override void NodeGUI () 
		{
			GUILayout.TextArea(Title);

			GUILayout.BeginHorizontal ();
			GUILayout.BeginVertical ();

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

			Outputs [0].DisplayLayout ();
			
			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();

			GUIContent content = new GUIContent(Text);
			GUILayout.TextArea(Text);
			float height = GUI.skin.textArea.CalcHeight(content, 140);
			if(this.rect != null)
			{
				this.rect.height = height + 65 + 18 * Inputs.Count;
			}
		}

		public override string GetXML () 
		{

			return "";
		}
	}
}