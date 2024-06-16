select transcript, snowflake.cortex.sentiment(???) 
from survey_transcripts;

select transcript,snowflake.cortex.summarize(???) 
from survey_transcripts;

SET prompt = 
'
Summarize this transcript in less than 100 words. 
Put the product name, sentiment and summary in JSON format. Keep the summary in 2 sentences
';

select snowflake.cortex.complete('llama2-70b-chat',concat('[INST]',$prompt,transcript,'[/INST]')) as summary
from ???;

select snowflake.cortex.complete('mixtral-8x7b',concat('[INST]',$prompt,transcript,'[/INST]')) as summary
from ???;

select snowflake.cortex.complete('mistral-7b',concat('[INST]',$prompt,transcript,'[/INST]')) as summary
from ???;

select snowflake.cortex.complete('gemma-7b',concat('[INST]',$prompt,transcript,'[/INST]')) as summary
from ???;

select snowflake.cortex.complete('gemma-7b',concat('[INST]',$prompt,transcript,'[/INST]')) as summary
from ???;