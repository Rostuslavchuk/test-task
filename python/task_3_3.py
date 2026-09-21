import pandas as pd

def load_daily_optimized(path: str, day: str):
    cols = ['event_time', 'app_id', 'media_source', 'revenue_usd'] 
    
    try:
        df = pd.read_csv(path, usecols=cols)
    except FileNotFoundError:
        return pd.DataFrame()
        
    df = df[df['event_time'].str.startswith(day, na=False)].copy()
    
    if df.empty:
        return pd.DataFrame(columns=["key", "revenue"])

    df['revenue_usd'] = pd.to_numeric(
        df['revenue_usd'].astype(str).str.replace(',', '.'),  # type: ignore
        errors='coerce'
    ).fillna(0.0)  # type: ignore
    
    df['key'] = df['app_id'].astype(str) + "-" + df['media_source'].astype(str)
    
    result = df.groupby('key', as_index=False)['revenue_usd'].sum()
    result = result.rename(columns={'revenue_usd': 'revenue'})  # type: ignore
    
    return result.sort_values("revenue", ascending=False)
