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
	[Node (false, "Dialogue/Dialogue Node")]
	public class DialogueNode : Node 
	{
		public const string ID = "dialogueNode";
		public override string GetID { get { return ID; } }

		public string SimpleResponse = "";
		public string DialogueNodeID = "";

		public override Node Create (Vector2 pos) 
		{
			DialogueNode node = CreateInstance<DialogueNode> ();

			node.rect = new Rect (pos.x, pos.y, 150, 75);

			node.name = "Dialogue Node " + DialogueNodeID;

			node.CreateInput ("", "Flow");
			node.CreateOutput ("Options", "Flow");
			node.CreateOutput ("Responses", "Flow");

			return node;
		}

		protected internal override void NodeGUI () 
		{
			

			this.name = "Dialogue Node " + DialogueNodeID;

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
			Outputs [1].DisplayLayout ();
			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();

			GUIContent content = new GUIContent(SimpleResponse);
			GUILayout.TextArea(SimpleResponse);
			float height = GUI.skin.textArea.CalcHeight(content, 140);
			if(this.rect != null)
			{
				this.rect.height = height + 70 + 18 * Inputs.Count;
			}

			Texture2D tex = ResourceManager.LoadTexture ("Textures/DialogNodeMarker.png");
			GUILayout.Box(tex);
		}

		public override string GetXML () 
		{
			
			return "";
		}
	}
}