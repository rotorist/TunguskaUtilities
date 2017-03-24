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
	[Node (false, "Dialogue/Dialogue Topic")]
	public class DialogueTopic : Node 
	{
		public const string ID = "dialogueTopic";
		public override string GetID { get { return ID; } }

		public string SimpleResponse = "";
		public string TopicID = "";
		public string Title = "";

		public override Node Create (Vector2 pos) 
		{
			DialogueTopic node = CreateInstance<DialogueTopic> ();

			node.rect = new Rect (pos.x, pos.y, 150, 75);
			node.name = "Dialogue Topic (" + TopicID + ")";

			node.CreateInput ("", "Flow");
			node.CreateOutput ("Next Node", "Flow");

			return node;
		}

		protected internal override void NodeGUI () 
		{


			this.name = "Topic " + TopicID + ": " + Title;

			GUILayout.BeginHorizontal ();
			GUILayout.BeginVertical ();


			for(int i=0; i<Inputs.Count; i++)
			{
				Inputs [i].DisplayLayout ();
			}

			GUILayout.EndVertical ();
			GUILayout.BeginVertical ();

			Outputs [0].DisplayLayout ();

			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();

			GUIContent content = new GUIContent(SimpleResponse);
			GUILayout.TextArea(SimpleResponse);
			float height = GUI.skin.textArea.CalcHeight(content, 140);
			if(this.rect != null)
			{
				this.rect.height = height + 60;
			}
		}

		public override string GetXML () 
		{

			return "";
		}
	}
}