import pandas as pd

def fix_country_code(code):
    if code.isna():
        return "XX"
    
    text_code = str(code).strip().upper()
    if len(text_code) == 2 and text_code.isalpha():
        return text_code
    return "XX"
    

def clean_events_data(df: pd.DataFrame):
    stats = {
        "unparseable_revenue": 0
    }

    df = df[df.get("is_test", False) != True].copy()

    bad_row_mask = df["event_id"].isna() | df["event_id"] == '' | df["event_time"].isna()

    bad_rows = df[bad_row_mask].copy()

    clean_df = df[~bad_row_mask].copy()
    if clean_df.empty:
        return clean_df, bad_rows, stats
    
    rev_str = df["revenue_usd"].replace({'': '0', 'NULL': '0'}).astype(str).str.replace(",", ".")
    rev_numeric = pd.to_numeric(rev_str, errors='coerce')
    stats["unparseable_revenue"] = int(rev_numeric.isna().sum())
    clean_df['revenue_usd'] = rev_numeric.fillna(0.0)

    clean_df["country"] = clean_df["country"].apply(fix_country_code)

    clean_df['event_time'] = pd.to_datetime(clean_df['event_time'], utc=True, errors='coerce')
    clean_df['ingested_at'] = pd.to_datetime(clean_df['ingested_at'], utc=True, errors='coerce')
    time_fail_mask = clean_df['event_time'].isna() | clean_df['ingested_at'].isna()

    bad_rows = pd.concat([bad_rows, clean_df[time_fail_mask]])

    clean_df = clean_df[~time_fail_mask].copy()
    clean_df = clean_df.sort_values(
        by=['ingested_at', 'event_time', 'revenue_usd'], 
        ascending=[False, False, False]
    )
    clean_df = clean_df.drop_duplicates(subset=['event_id'], keep='first')

    return clean_df, bad_rows, stats

