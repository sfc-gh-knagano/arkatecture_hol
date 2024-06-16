import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import plotly.express as px
import json

st.set_page_config(layout='wide')
session = get_active_session()

supported_llms = ['mixtral-8x7b','mistral-7b','llama2-70b-chat','gemma-7b']

def sentiment_analysis():
    with st.container():
        st.header("Sentiment Analysis With Snowflake Cortex")

        tablesList = []
        dfTables = session.sql("SHOW TABLES IN SCHEMA")
        dfTablesLocal = pd.DataFrame(dfTables.collect())
        dfTablesLocal.columns = dfTablesLocal.columns.str.upper().str.strip()
        dfTablesLocal = dfTablesLocal[(dfTablesLocal["NAME"].str.contains("SURVEY_TRANSCRIPTS"))]

        objTables  = json.loads(dfTablesLocal.to_json(orient="records", date_format="iso"))
        for x in objTables:
            x["FQON"] = x["DATABASE_NAME"] + "." + x["SCHEMA_NAME"] +"." +x["NAME"]
            tablesList.append(x["FQON"])

        tablesList.sort()

        sourceTable = st.selectbox(label="Select Table to Edit", options=tablesList)

        entered_text = st.text_input("Enter text",label_visibility="hidden",placeholder='Which column would you like to run sentiment detection on')
        df = session.table(sourceTable)
        st.table(df)
        
        if entered_text:
            entered_text = entered_text.replace("'", "\\'")

            cortex_response = session.sql(f"select rep_id, transcript, snowflake.cortex.???(transcript) from ???;").to_pandas()
            st.caption("Score is between -1 and 1; -1 = Most negative, 1 = Positive, 0 = Neutral")  
            st.write(cortex_response)

            response_for_graph = session.sql(f"SELECT rep_id, AVG(snowflake.cortex.???(transcript)) AS avg_sentiment FROM ??? GROUP BY rep_id;").to_pandas()  

            positive_color = 'Positive'
            negative_color = 'Negative'

            colors = ['blue' if sentiment > 0 else 'red' for sentiment in response_for_graph['AVG_SENTIMENT']]

            # Map each unique REP_ID to its corresponding color
            colors_dict = dict(zip(response_for_graph['REP_ID'].unique(), colors))

            # Add a new column to the DataFrame with the corresponding color for each REP_ID
            response_for_graph['LEGEND'] = response_for_graph['REP_ID'].map(colors_dict)

            # Convert REP_ID to string
            response_for_graph['REP_ID'] = response_for_graph['REP_ID'].astype(str)

            # Use Plotly to create a custom bar chart with colors based on sentiment
            fig = px.bar(response_for_graph, x="REP_ID", y="AVG_SENTIMENT", color='LEGEND',
                         labels={"REP_ID": "Rep ID", "AVG_SENTIMENT": "Average Sentiment"},
                         color_discrete_map={'blue': 'blue', 'red': 'red'})

            fig.update_layout(
                xaxis=dict(
                    tickmode='linear',  # Use linear tick mode
                    tick0=1,  # Start ticks at 1
                    dtick=1  # Set the tick interval to 1
                ),
                yaxis=dict(
                    dtick=0.2
                ),
                showlegend=False
            )
            st.plotly_chart(fig)
    
def summarize():
    with st.container():
        st.header("JSON Summary With Snowflake Cortex")
        selected_llm = st.selectbox('Select Model',supported_llms)
        entered_text = st.text_area("Enter text",label_visibility="hidden",height=400,placeholder='For example: call transcript')    
        if entered_text:
            entered_text = entered_text.replace("'", "\\'")
            prompt = f"Summarize this transcript in less than 100 words. Put the industry, compliments, complaints and summary in JSON format: {entered_text}"
            cortex_prompt = "'[INST] " + prompt + " [/INST]'"
            cortex_response = session.sql(f"select snowflake.cortex.???('{selected_llm}', {cortex_prompt}) as response").to_pandas().iloc[0]['RESPONSE']
            if selected_llm != 'gemma-7b':
                st.json(cortex_response)
            else:
                st.write(cortex_response)

page_names_to_funcs = {
    "Sentiment Analysis": sentiment_analysis,
    "JSON Summary": summarize
}

selected_page = st.sidebar.selectbox("Select", page_names_to_funcs.keys())
page_names_to_funcs[selected_page]()