import "./messenger.css";

import Topbar from "../../components/topbar/Topbar";
import { AuthContext } from "../../context/AuthContext";
import Conversation from "../../components/conversation/Conversation";
import Message from "../../components/message/Message";
import ChatOnline from "../../components/chatOnline/ChatOnline";

import React, { useContext, useState, useEffect, useRef } from "react";
import axios from "axios";

const backend_url = process.env.REACT_APP_BACKEND_URL;

export default function Messenger() {
  const { user: currentUser } = useContext(AuthContext);
  const [conversations, setConversations] = useState([]);
  const [currentChat, setCurrentChat] = useState();
  const [messages, setMessages] = useState();
  const [newMessage, setNewMessage] = useState("");
  const scrollRef = useRef();

  useEffect(() => {
    const getConversation = async () => {
      try {
        const res = await axios.get(
          `${backend_url}/conversation/${currentUser._id}`
        );
        setConversations(res.data);
      } catch (err) {
        console.log(err);
      }
    };
    getConversation();
  }, [currentUser._id]);

  useEffect(() => {
    const getMessages = async () => {
      try {
        const res = await axios.get(
          `${backend_url}/message/${currentChat?._id}`
        );
        setMessages(res.data);
      } catch (err) {
        console.log(err);
      }
    };
    getMessages();
  }, [currentChat]);

  const submitMessage = async (e) => {
    e.preventDefault();
    const message = {
      conversationId: currentChat._id,
      senderId: currentUser._id,
      text: newMessage,
    };

    try {
      const res = await axios.post(`${backend_url}/message`, message);
      setMessages([...messages, res.data]);
      setNewMessage("");
    } catch (err) {
      console.log(err);
    }
  };

  useEffect(() => {
    scrollRef.current?.scrollIntoView({
      behavior: "smooth",
    });
  }, [messages]);

  return (
    <React.Fragment>
      <Topbar />
      <div className="messenger">
        <div className="chatMenu">
          <div className="chatMenuWrapper">
            <input
              placeholder="Search for friends"
              type="text"
              className="chatMenuInput"
            />
            {conversations.map((c) => (
              <div onClick={() => setCurrentChat(c)}>
                <Conversation conversation={c} />
              </div>
            ))}
          </div>
        </div>
        <div className="chatBox">
          <div className="chatBoxWrapper">
            {currentChat ? (
              <React.Fragment>
                <div className="chatBoxTop">
                  {messages.map((m) => (
                    <div ref={scrollRef}>
                      <Message
                        myside={m?.senderId === currentUser._id}
                        message={m}
                      />
                    </div>
                  ))}
                </div>
                <div className="chatBoxBottom">
                  <textarea
                    placeholder="Write something here"
                    name=""
                    id=""
                    cols="30"
                    rows="10"
                    className="chatMessageInput"
                    onChange={(e) => setNewMessage(e.target.value)}
                    value={newMessage}
                  ></textarea>
                  <button className="chatSubmitButton" onClick={submitMessage}>
                    Send
                  </button>
                </div>
              </React.Fragment>
            ) : (
              <span className="noConversationSelected">
                Open a conversation to start a chat
              </span>
            )}
          </div>
        </div>
        <div className="chatOnline">
          <div className="chatOnlineWrapper">
            <ChatOnline
              onlineUsers={onlineUsers}
              currentUserId={currentUser._id}
              setCurrentChat={setCurrentChat}
            />
          </div>
        </div>
      </div>
    </React.Fragment>
  );
}
