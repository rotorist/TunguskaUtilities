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
	[Node (false, "Dialogue/Dialogue Root")]
	public class DialogueRoot : Node 
	{
		public const string ID = "dialogueRoot";
		public override string GetID { get { return ID; } }

		public string DialogueName;
		public string IntroText;

		private XmlWriter _xmlWriter;
		private List<DialogueNode> _processedNodes;

		public override Node Create (Vector2 pos) 
		{
			DialogueRoot node = CreateInstance<DialogueRoot> ();

			node.rect = new Rect (pos.x, pos.y, 150, 75);
			node.name = "Dialogue Root";

			node.CreateOutput ("Topics", "Flow");
			node.CreateOutput ("Next Node", "Flow");

			return node;
		}

		protected internal override void NodeGUI () 
		{
			GUILayout.BeginHorizontal ();
			GUILayout.BeginVertical ();

			GUILayout.Label(DialogueName);

			if(GUILayout.Button("Save"))
			{
				string path = EditorUtility.SaveFilePanelInProject("Save Dialogue XML", DialogueName, "xml", "", NodeEditor.editorPath + "Resources/DialogueXML/");
				if (!string.IsNullOrEmpty (path))
					SaveXML(path);
			}

			GUILayout.EndVertical ();
			GUILayout.BeginVertical ();

			Outputs [0].DisplayLayout ();
			Outputs [1].DisplayLayout ();
			GUILayout.EndVertical ();
			GUILayout.EndHorizontal ();


		}


		public void SaveXML(string path) 
		{
			_processedNodes = new List<DialogueNode>();

			XmlWriterSettings settings = new XmlWriterSettings();
			settings.Indent = true;
			settings.IndentChars = "    "; // note: default is two spaces
			settings.NewLineOnAttributes = false;

			_xmlWriter = XmlWriter.Create(path, settings);

			_xmlWriter.WriteStartDocument();

			_xmlWriter.WriteDocType("dialogue", null, null, "<!ATTLIST node id ID #IMPLIED>");

			_xmlWriter.WriteStartElement("dialogue");
			_xmlWriter.WriteStartElement("intro");
			_xmlWriter.WriteStartElement("text");
			_xmlWriter.WriteString(IntroText);
			_xmlWriter.WriteEndElement();
			_xmlWriter.WriteStartElement("next_node");

			if(Outputs[1].connections[0] != null)
			{
				DialogueNode dialogueNode = (DialogueNode)Outputs[1].connections[0].body;
				_xmlWriter.WriteAttributeString("id", dialogueNode.DialogueNodeID.ToString());
			}
			_xmlWriter.WriteEndElement();
			_xmlWriter.WriteEndElement();

			//write topics
			foreach(NodeInput connection in Outputs[0].connections)
			{
				if(connection != null)
				{
					SaveTopic(connection.body);
				}
			}

			if(Outputs[1].connections[0] != null)
			{
				SaveNode(Outputs[1].connections[0].body);
			}

			_xmlWriter.WriteEndDocument();
			_xmlWriter.Close();

		}

		private void SaveTopic(Node rawNode)
		{
			if(rawNode.GetID == "dialogueTopic")
			{
				//save a list of next nodes to be processed later
				DialogueNode nextNode = null;

				DialogueTopic topic = (DialogueTopic)rawNode;
				if(String.IsNullOrEmpty(topic.TopicID))
				{
					Debug.LogError("Topic has no ID!");
				}

				_xmlWriter.WriteStartElement("topic");
				_xmlWriter.WriteAttributeString("id", topic.TopicID);

				if(!String.IsNullOrEmpty(topic.Title))
				{
					_xmlWriter.WriteStartElement("title");
					_xmlWriter.WriteString(topic.Title);
					_xmlWriter.WriteFullEndElement();
				}

				if(!String.IsNullOrEmpty(topic.SimpleResponse))
				{
					_xmlWriter.WriteStartElement("response");
					_xmlWriter.WriteStartElement("text");
					_xmlWriter.WriteString(topic.SimpleResponse);
					_xmlWriter.WriteEndElement();
					_xmlWriter.WriteFullEndElement();
				}

				//find next node if there is one
				if(topic.Outputs[0].connections.Count > 0)
				{
					DialogueNode node = (DialogueNode)topic.Outputs[0].connections[0].body;
					_xmlWriter.WriteStartElement("next_node");
					_xmlWriter.WriteAttributeString("id", node.DialogueNodeID);
					_xmlWriter.WriteEndElement();
					nextNode = node;
				}

				_xmlWriter.WriteFullEndElement();

				if(nextNode != null && !_processedNodes.Contains(nextNode))
				{
					SaveNode(nextNode);
				}

			}
		}


		private void SaveNode(Node rawNode)
		{
			if(rawNode.GetID == "dialogueNode")
			{
				
				//save a list of next nodes to be processed later
				List<DialogueNode> nextNodes = new List<DialogueNode>();

				//write elements of a node
				DialogueNode node = (DialogueNode)rawNode;

				if(String.IsNullOrEmpty(node.DialogueNodeID))
				{
					Debug.LogError("Node has no ID!");
				}

				//mark this node processed
				_processedNodes.Add(node);
					
				_xmlWriter.WriteStartElement("node");
				_xmlWriter.WriteAttributeString("id", node.DialogueNodeID);

				foreach(NodeInput response in node.Outputs[1].connections)
				{
					//write each response node
					DialogueResponse responseNode = (DialogueResponse)response.body;
					_xmlWriter.WriteStartElement("response");
					if(responseNode.Inputs[0].connection != null)
					{
						SaveCondition(responseNode.Inputs[0].connection.body);
					}
					//write response data
					_xmlWriter.WriteStartElement("text");
					_xmlWriter.WriteString(responseNode.ResponseText);
					_xmlWriter.WriteEndElement();

					if(!String.IsNullOrEmpty(responseNode.EventID))
					{
						_xmlWriter.WriteStartElement("event");
						_xmlWriter.WriteAttributeString("name", responseNode.EventID);
						_xmlWriter.WriteEndElement();
					}

					_xmlWriter.WriteEndElement();
				}

				if(!String.IsNullOrEmpty(node.SimpleResponse))
				{
					_xmlWriter.WriteStartElement("response");
					_xmlWriter.WriteStartElement("text");
					_xmlWriter.WriteString(node.SimpleResponse);
					_xmlWriter.WriteEndElement();
					_xmlWriter.WriteEndElement();
				}

				foreach(NodeInput option in node.Outputs[0].connections)
				{
					//write each option node
					DialogueOption optionNode = (DialogueOption)option.body;
					_xmlWriter.WriteStartElement("option");
					if(optionNode.Inputs[0].connection != null)
					{
						SaveCondition(optionNode.Inputs[0].connection.body);
					}
					//write option data
					_xmlWriter.WriteStartElement("title");
					_xmlWriter.WriteString(optionNode.Title);
					_xmlWriter.WriteEndElement();
					_xmlWriter.WriteStartElement("text");
					_xmlWriter.WriteString(optionNode.Text);
					_xmlWriter.WriteEndElement();

					//find next node if there is one
					if(optionNode.Outputs[0].connections.Count > 0)
					{
						DialogueNode nextNode = (DialogueNode)optionNode.Outputs[0].connections[0].body;
						_xmlWriter.WriteStartElement("next_node");
						_xmlWriter.WriteAttributeString("id", nextNode.DialogueNodeID);
						_xmlWriter.WriteEndElement();
						nextNodes.Add(nextNode);
					}

					_xmlWriter.WriteEndElement();

				}

				_xmlWriter.WriteEndElement();

				foreach(DialogueNode n in nextNodes)
				{
					if(!_processedNodes.Contains(n))
					{
						SaveNode(n);
					}
				}

			}

		}

		private void SaveCondition(Node rawNode)
		{
			if(rawNode.GetID == "dialogueCondition")
			{
				DialogueCondition condition = (DialogueCondition)rawNode;
				_xmlWriter.WriteStartElement("condition");
				_xmlWriter.WriteAttributeString("name", condition.ConditionName);
				_xmlWriter.WriteAttributeString("story", condition.StoryConditionName);
				_xmlWriter.WriteAttributeString("compare", condition.CompareValue);
				_xmlWriter.WriteAttributeString("op", condition.ConvertOpToInt(condition.Operation).ToString());
				_xmlWriter.WriteEndElement();


			}
			else if(rawNode.GetID == "logicNode")
			{
				LogicNode logic = (LogicNode)rawNode;
				_xmlWriter.WriteStartElement("logic");
				_xmlWriter.WriteAttributeString("type", logic.Operation.ToString());
				//if there's any inputs, traverse backwards for more condition nodes
				foreach(NodeInput input in logic.Inputs)
				{
					if(input.connection != null)
					{
						SaveCondition(input.connection.body);
					}
				}

				_xmlWriter.WriteEndElement();
			}
		}


	}
}