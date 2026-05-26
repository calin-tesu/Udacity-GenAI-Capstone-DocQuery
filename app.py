import os
import streamlit as st
from dotenv import load_dotenv
from bedrock_utils import query_knowledge_base, generate_response, valid_prompt, build_rag_prompt

# Load variables from a .env file if it exists in the current directory
load_dotenv()

# --- Page config ---
st.set_page_config(
    page_title="DocQuery",
    page_icon="🔍",
    layout="wide"
)

# --- UI Helpers ---
def display_sources(sources):
    """Displays retrieved document chunks in a consistent, formatted expander."""
    if not sources:
        return
        
    with st.expander("📄 Sources", expanded=False):
        for i, source in enumerate(sources, 1):
            filename = source["source"].split("/")[-1] if source["source"] != "Unknown source" else "Unknown"
            st.markdown(f"**{i}. {filename}** (relevance: {source['score']})")
            st.caption(source["source"])
            st.markdown(f"> {source['text'][:300]}{'...' if len(source['text']) > 300 else ''}")

# --- Header ---
st.title("🔍 DocQuery")
st.caption("Ask questions about your documents — answers grounded in your private data.")

# --- Sidebar ---
st.sidebar.header("Configuration")

model_id = st.sidebar.selectbox(
    "LLM Model",
    [
        "anthropic.claude-3-haiku-20240307-v1:0",
        "anthropic.claude-3-5-sonnet-20240620-v1:0",
    ],
    help="Haiku is faster and cheaper. Sonnet is more capable."
)

# Read KB ID from environment variable, allow sidebar override for flexibility
default_kb_id = os.environ.get("KNOWLEDGE_BASE_ID", "")
kb_id = st.sidebar.text_input(
    "Knowledge Base ID",
    value=default_kb_id,
    help="Set KNOWLEDGE_BASE_ID env var to avoid entering this manually."
)

num_results = st.sidebar.slider(
    "Retrieved chunks",
    min_value=1, max_value=10, value=3,
    help="How many document chunks to retrieve per query."
)

temperature = st.sidebar.select_slider(
    "Temperature",
    options=[round(i / 10, 1) for i in range(0, 11)],
    value=0.7,
    help="Higher = more creative. Lower = more factual."
)

top_p = st.sidebar.select_slider(
    "Top P",
    options=[round(i / 100, 2) for i in range(0, 101)],
    value=0.9,
)

st.sidebar.divider()
if st.sidebar.button("🗑️ Clear conversation"):
    st.session_state.messages = []
    st.rerun()

# --- Validation ---
if not kb_id or kb_id == "your-knowledge-base-id":
    st.warning(
        "⚠️ No Knowledge Base ID configured. "
        "Set the `KNOWLEDGE_BASE_ID` environment variable or enter it in the sidebar."
    )
    st.stop()

# --- Chat history ---
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display existing messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])
        if message["role"] == "assistant" and message.get("sources"):
            display_sources(message["sources"])

# --- Chat input ---
if prompt := st.chat_input("Ask a question about your documents..."):

    # Validate KB ID is set
    if not kb_id:
        st.error("Please enter a Knowledge Base ID in the sidebar.")
        st.stop()

    # Display user message
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # Generate response
    with st.chat_message("assistant"):
        with st.spinner("Searching documents and generating answer..."):
            try:
                # Guardrail check
                if not valid_prompt(prompt, model_id):
                    response_text = (
                        "⚠️ I'm unable to process that request. "
                        "Please ask a clear, respectful question about your documents."
                    )
                    sources = []
                else:
                    # Retrieve relevant chunks
                    kb_results = query_knowledge_base(prompt, kb_id, num_results)

                    if not kb_results:
                        response_text = (
                            "I couldn't find relevant information in the knowledge base for that question. "
                            "Try rephrasing or check that your documents have been ingested and synced."
                        )
                        sources = []
                    else:
                        # Build context from retrieved chunks
                        full_prompt = build_rag_prompt(prompt, kb_results)
                        response_text = generate_response(full_prompt, model_id, temperature, top_p)
                        sources = kb_results

            except Exception as e:
                response_text = f"❌ An unexpected error occurred: {str(e)}"
                sources = []

        # Display response
        st.markdown(response_text)

        # Display sources
        display_sources(sources)

    # Save to history
    st.session_state.messages.append({
        "role": "assistant",
        "content": response_text,
        "sources": sources
    })