#!/usr/bin/env python3
"""
NFL Process Mining Transformation Pipeline

This script executes the complete transformation from NFL play-by-play data
to process mining event log format using the sophisticated SQL methodology
developed for domain-to-process analysis.

Execution: python run_transformation.py
Output: outputs/nfl_eventlog.csv (ready for PM4PY or other process mining tools)

Author: Nick Blackbourn
Data Source: nflverse (https://github.com/nflverse)
"""

import sqlite3
import pandas as pd
import requests
import os
import sys
from pathlib import Path

# Configuration
DATA_URL = "https://github.com/nflverse/nflverse-data/releases/download/pbp/play_by_play_2007.csv"
DATA_DIR = Path("data")
SQL_FILE = Path("src/transform_data.sql")
OUTPUT_DIR = Path("outputs")
OUTPUT_FILE = OUTPUT_DIR / "nfl_eventlog.csv"

def download_nflverse_data():
    """
    Download NFL 2007 play-by-play data from nflverse repository.
    
    Returns:
        pandas.DataFrame: Raw NFL play-by-play data
    """
    print("📥 Downloading NFL 2007 play-by-play data from nflverse...")
    
    try:
        # Download data directly into memory (no need to save large file)
        df = pd.read_csv(DATA_URL, low_memory=False)
        print(f"✅ Downloaded {len(df):,} plays from nflverse")
        return df
        
    except Exception as e:
        print(f"❌ Error downloading data: {e}")
        print("Please check your internet connection and try again.")
        sys.exit(1)

def execute_sql_transformation(raw_data):
    """
    Execute the SQL transformation pipeline using SQLite in-memory database.
    
    Args:
        raw_data (pandas.DataFrame): Raw NFL play-by-play data
        
    Returns:
        pandas.DataFrame: Transformed event log
    """
    print("⚙️  Executing SQL transformation pipeline...")
    
    # Create in-memory SQLite database
    conn = sqlite3.connect(':memory:')
    
    try:
        # Load raw data into SQLite
        print("   📊 Loading data into SQLite...")
        raw_data.to_sql('raw_data', conn, index=False, if_exists='replace')
        
        # Read and execute SQL transformation
        print("   🔄 Executing transformation SQL...")
        with open(SQL_FILE, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Split SQL into individual statements and execute
        statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip() and not stmt.strip().startswith('/*')]
        
        for i, statement in enumerate(statements):
            if statement and not statement.startswith('--'):
                try:
                    conn.execute(statement)
                except sqlite3.Error as e:
                    print(f"❌ Error in SQL statement {i+1}: {e}")
                    raise
        
        # Extract final result
        print("   📤 Extracting transformed event log...")
        event_log = pd.read_sql('SELECT * FROM final_cleaned_dataset', conn)
        
        return event_log
        
    except Exception as e:
        print(f"❌ SQL transformation failed: {e}")
        sys.exit(1)
        
    finally:
        conn.close()

def validate_transformation(event_log):
    """
    Perform basic validation to ensure transformation succeeded.
    
    Args:
        event_log (pandas.DataFrame): Transformed event log
        
    Returns:
        bool: True if validation passes
    """
    print("🔍 Validating transformation results...")
    
    # Required columns for process mining
    required_columns = ['case_id', 'activity_name', 'transformed_time']
    missing_columns = [col for col in required_columns if col not in event_log.columns]
    
    if missing_columns:
        print(f"❌ Missing required columns: {missing_columns}")
        return False
    
    # Check data quality
    if event_log.empty:
        print("❌ Event log is empty")
        return False
        
    if event_log['case_id'].isna().any():
        print("❌ Found NULL case_id values")
        return False
        
    if event_log['activity_name'].isna().any():
        print("❌ Found NULL activity_name values")
        return False
    
    # Verify New England data only
    if 'posteam' in event_log.columns:
        unique_teams = event_log['posteam'].unique()
        if len(unique_teams) != 1 or unique_teams[0] != 'NE':
            print(f"❌ Expected only NE data, found: {unique_teams}")
            return False
    
    # Basic statistics
    num_events = len(event_log)
    num_cases = event_log['case_id'].nunique()
    num_activities = event_log['activity_name'].nunique()
    
    print(f"✅ Validation passed:")
    print(f"   📊 Events: {num_events:,}")
    print(f"   🏈 Drives (cases): {num_cases:,}")
    print(f"   🎯 Activity types: {num_activities}")
    
    return True

def save_output(event_log):
    """
    Save the event log to CSV format for process mining tools.
    
    Args:
        event_log (pandas.DataFrame): Transformed event log
    """
    print("💾 Saving event log...")
    
    # Ensure output directory exists
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # Save to CSV
    event_log.to_csv(OUTPUT_FILE, index=False)
    print(f"✅ Event log saved to: {OUTPUT_FILE}")

def display_sample_output(event_log):
    """
    Display sample rows from the event log for verification.
    
    Args:
        event_log (pandas.DataFrame): Transformed event log
    """
    print("\n📋 Sample Event Log Output:")
    print("=" * 80)
    
    # Show key columns for process mining
    sample_columns = ['case_id', 'activity_name', 'transformed_time', 'down', 'yards_gained']
    available_columns = [col for col in sample_columns if col in event_log.columns]
    
    sample_data = event_log[available_columns].head(10)
    print(sample_data.to_string(index=False))
    
    print("\n📈 Activity Distribution (Top 10):")
    activity_counts = event_log['activity_name'].value_counts().head(10)
    for activity, count in activity_counts.items():
        print(f"   {activity}: {count}")

def main():
    """Main execution pipeline."""
    print("🏈 NFL Process Mining Transformation Pipeline")
    print("=" * 50)
    
    try:
        # Step 1: Download data
        raw_data = download_nflverse_data()
        
        # Step 2: Transform data
        event_log = execute_sql_transformation(raw_data)
        
        # Step 3: Validate results
        if not validate_transformation(event_log):
            print("❌ Validation failed. Transformation incomplete.")
            sys.exit(1)
        
        # Step 4: Save output
        save_output(event_log)
        
        # Step 5: Display sample
        display_sample_output(event_log)
        
        print("\n🎉 Transformation complete! Event log ready for process mining analysis.")
        print(f"📁 Output file: {OUTPUT_FILE}")
        print("\n📖 Next steps:")
        print("   1. Import the CSV into your process mining tool (PM4PY, ProM, Celonis)")
        print("   2. Use case_id as Case ID, activity_name as Activity, transformed_time as Timestamp")
        print("   3. Explore process patterns, variants, and performance metrics")
        
    except KeyboardInterrupt:
        print("\n⏹️  Transformation cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()