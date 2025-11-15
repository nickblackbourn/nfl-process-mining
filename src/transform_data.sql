/*
================================================================================
NFL PLAY-BY-PLAY TO PROCESS MINING EVENT LOG TRANSFORMATION
================================================================================

This SQL script transforms NFL play-by-play data into a process mining event log,
demonstrating advanced methodology for converting domain-specific data into 
process-analyzable format.

PROCESS MINING CONCEPTS APPLIED:
- CASE IDENTIFICATION: Each NFL offensive drive becomes a distinct process instance
- ACTIVITY MAPPING: Strategic play classifications that preserve decision context
- TEMPORAL ORDERING: Game timeline converted to process mining timestamps
- OUTCOME ENRICHMENT: Drive-level results enable process success analysis

Author: Nick Blackbourn
Data Source: nflverse (https://github.com/nflverse)
Target: PM4PY compatible event log format
================================================================================
*/

-- ============================================================================
-- STEP 0: CLEAN SLATE - PREPARE FOR TRANSFORMATION
-- ============================================================================
-- Best practice: Always start with clean environment for reproducible results
-- This ensures consistent execution regardless of previous state

DROP TABLE IF EXISTS cleaned_dataset;
DROP TABLE IF EXISTS final_cleaned_dataset;
DROP TABLE IF EXISTS drive_results;

-- ============================================================================
-- STEP 1: CASE-LEVEL AGGREGATION - CREATE DRIVE OUTCOME METRICS
-- ============================================================================
-- PROCESS MINING RATIONALE: In process mining, we need case-level attributes
-- that describe the overall outcome of each process instance (drive).
-- This enables analysis of which process paths lead to successful outcomes.
--
-- NFL CONTEXT: A drive is a complete offensive possession, representing one
-- complete "case" in our process. Drive outcomes (scoring vs. turnover) are 
-- the key success metrics we want to correlate with process paths.

CREATE TABLE drive_results AS
SELECT
    game_id,
    drive,
    -- TOUCHDOWN DETECTION: Any scoring play within the drive
    -- This captures the ultimate success outcome for offensive process analysis
    MAX(CASE WHEN CAST(touchdown AS INTEGER) = 1 THEN 1 ELSE 0 END) AS drive_touchdown,
    
    -- FIELD GOAL SUCCESS: Alternative scoring outcome for drives that reach red zone
    -- Important for understanding different process termination patterns
    MAX(CASE WHEN field_goal_result = 'made' THEN 1 ELSE 0 END) AS drive_field_goal,
    
    -- COMPOSITE SUCCESS METRIC: Any form of scoring (touchdown OR field goal)
    -- This binary outcome enables process mining analysis of successful vs. failed drives
    MAX(CASE WHEN CAST(touchdown AS INTEGER) = 1 OR field_goal_result = 'made' THEN 1 ELSE 0 END) AS drive_any_score,
    
    -- FAILURE OUTCOME: Turnovers represent process termination due to error
    -- Critical for identifying process paths that lead to negative outcomes
    MAX(CASE WHEN CAST(interception AS INTEGER) = 1 OR CAST(fumble AS INTEGER) = 1 THEN 1 ELSE 0 END) AS drive_turnover
FROM raw_data
GROUP BY game_id, drive;

-- ============================================================================
-- STEP 2: PROCESS SCOPE DEFINITION - FILTER AND ENRICH CORE DATASET
-- ============================================================================
-- PROCESS MINING RATIONALE: Define the process boundary by filtering to specific
-- organizational unit (New England offense) and enriching with case-level outcomes.
-- This creates the foundation dataset with both event-level and case-level data.
--
-- NFL CONTEXT: Focus on one team's offensive strategy to create coherent process
-- analysis. Different teams have different strategic approaches, so mixing would
-- create noise in process discovery algorithms.

CREATE TABLE cleaned_dataset AS
SELECT 
    -- CASE IDENTIFIERS: These will be used to create unique process instance IDs
    r.game_id,
    r.drive,
    
    -- ACTIVITY FOUNDATIONS: Raw activity data that will be mapped to process activities
    r.play_type,
    r.time,  -- Original timestamp - will be transformed for process mining compatibility
    
    -- STRATEGIC CONTEXT: NFL-specific attributes that enable sophisticated activity classification
    -- These preserve the strategic decision-making context within each activity
    r.pass_length,    -- Short vs. deep passes represent different strategic choices
    r.pass_location,  -- Left/middle/right indicates directional strategy
    r.run_location,   -- Running direction shows offensive line strategy
    r.run_gap,        -- Specific gap (tackle/guard/end) shows tactical execution
    
    -- OUTCOME ATTRIBUTES: Activity-level results that will inform activity naming
    r.field_goal_result,
    r.extra_point_result,
    r.two_point_conv_result,
    CAST(r.touchdown AS INTEGER) AS touchdown,
    CAST(r.interception AS INTEGER) AS interception,
    CAST(r.fumble AS INTEGER) AS fumble,
    
    -- CONTEXTUAL DATA: Additional attributes for process analysis enrichment
    r.desc,                    -- Play description for edge case handling
    r.down,                    -- Game situation context
    r.yards_gained,            -- Activity outcome measurement
    r.quarter_seconds_remaining, -- Temporal context for timestamp transformation
    r.posteam,                 -- Organizational unit verification
    
    -- RESOURCE ATTRIBUTES: Personnel involved in each activity (optional for basic process mining)
    r.passer_player_name AS passer,
    r.receiver_player_name AS receiver,
    r.rusher_player_name AS runner,
    
    -- CASE-LEVEL ENRICHMENT: Join drive outcomes to enable process success analysis
    d.drive_touchdown,
    d.drive_field_goal,
    d.drive_any_score,
    d.drive_turnover
FROM raw_data r
JOIN drive_results d
    ON r.game_id = d.game_id AND r.drive = d.drive
-- PROCESS BOUNDARY: Filter to New England offensive plays only
-- This creates a coherent process scope for meaningful analysis
WHERE r.posteam = 'NE';

-- ============================================================================
-- STEP 3: CASE IDENTIFICATION - CREATE PROCESS MINING CASE_ID
-- ============================================================================
-- PROCESS MINING RATIONALE: Every event in a process log must be linked to a 
-- unique case identifier. This enables process mining algorithms to reconstruct
-- process instances and analyze flow patterns between activities.
--
-- METHODOLOGY: Combine game_id + drive to create unique process instances.
-- Each drive represents one complete execution of the "offensive possession" process.

ALTER TABLE cleaned_dataset
ADD COLUMN case_id VARCHAR(255);

-- Generate unique case identifiers by combining game and drive
-- Format: "2007_01_NE_NYJ_1" (year_week_team_opponent_drivenumber)
UPDATE cleaned_dataset
SET case_id = game_id || '_' || drive;

-- ============================================================================
-- STEP 4: ACTIVITY MAPPING - SOPHISTICATED DOMAIN-TO-PROCESS TRANSFORMATION
-- ============================================================================
-- PROCESS MINING RATIONALE: Transform domain-specific actions into meaningful
-- process activities. This requires deep domain expertise to create activity
-- classifications that preserve strategic decision-making context while being
-- suitable for process analysis algorithms.
--
-- DESIGN PHILOSOPHY: Balance between granularity (preserving strategic nuance)
-- and analyzability (avoiding too many rare activities that fragment analysis).

ALTER TABLE cleaned_dataset
ADD COLUMN activity_name VARCHAR(255);

UPDATE cleaned_dataset
SET activity_name = CASE
    -- ========================================================================
    -- PASSING STRATEGY ACTIVITIES
    -- Strategic context: Pass direction and depth represent distinct tactical decisions
    -- Process relevance: Different pass types have different success rates and flow patterns
    -- ========================================================================
    
    -- DETAILED PASS CLASSIFICATION: Preserve strategic decision context
    WHEN play_type = 'pass' AND pass_length = 'short' AND pass_location = 'left' THEN 'pass short left'
    WHEN play_type = 'pass' AND pass_length = 'short' AND pass_location = 'middle' THEN 'pass short middle'
    WHEN play_type = 'pass' AND pass_length = 'short' AND pass_location = 'right' THEN 'pass short right'
    WHEN play_type = 'pass' AND pass_length = 'deep' AND pass_location = 'left' THEN 'pass deep left'
    WHEN play_type = 'pass' AND pass_length = 'deep' AND pass_location = 'middle' THEN 'pass deep middle'
    WHEN play_type = 'pass' AND pass_length = 'deep' AND pass_location = 'right' THEN 'pass deep right'
    
    -- FALLBACK FOR INCOMPLETE DATA: Handle missing strategic attributes gracefully
    WHEN play_type = 'pass' AND (pass_length IS NULL OR pass_location IS NULL) THEN 'pass'
    
    -- ========================================================================
    -- RUSHING STRATEGY ACTIVITIES  
    -- Strategic context: Run location and gap represent specific offensive line schemes
    -- Process relevance: Ground game strategy flows differently than passing attacks
    -- ========================================================================
    
    -- DETAILED RUN CLASSIFICATION: Preserve tactical execution context
    WHEN play_type = 'run' AND run_location = 'left' AND run_gap = 'tackle' THEN 'run left tackle'
    WHEN play_type = 'run' AND run_location = 'left' AND run_gap = 'guard' THEN 'run left guard'
    WHEN play_type = 'run' AND run_location = 'left' AND run_gap = 'end' THEN 'run left end'
    WHEN play_type = 'run' AND run_location = 'middle' THEN 'run middle'
    WHEN play_type = 'run' AND run_location = 'right' AND run_gap = 'guard' THEN 'run right guard'
    WHEN play_type = 'run' AND run_location = 'right' AND run_gap = 'tackle' THEN 'run right tackle'
    WHEN play_type = 'run' AND run_location = 'right' AND run_gap = 'end' THEN 'run right end'
    
    -- FALLBACK FOR INCOMPLETE DATA: Ensure all runs are captured even with missing details
    WHEN play_type = 'run' AND (run_location IS NULL OR run_gap IS NULL) THEN 'run'
    
    -- ========================================================================
    -- SCORING ACTIVITIES
    -- Process relevance: These represent successful process termination events
    -- Outcome tracking: Success/failure rates are key process KPIs
    -- ========================================================================
    
    -- FIELD GOAL ATTEMPTS: Include outcome in activity name for process analysis
    WHEN play_type = 'field_goal' AND field_goal_result = 'made' THEN 'field goal - made'
    WHEN play_type = 'field_goal' AND field_goal_result = 'missed' THEN 'field goal - missed'
    
    -- EXTRA POINT ATTEMPTS: Post-touchdown process activities
    WHEN play_type = 'extra_point' AND extra_point_result = 'made' THEN 'extra point - made'
    WHEN play_type = 'extra_point' AND extra_point_result = 'missed' THEN 'extra point - missed'
    
    -- TWO-POINT CONVERSIONS: High-risk alternative scoring strategy
    WHEN play_type = 'two_point' AND two_point_conv_result = 'made' THEN 'two point conversion - made'
    WHEN play_type = 'two_point' AND two_point_conv_result = 'missed' THEN 'two point conversion - missed'
    
    -- ========================================================================
    -- NEGATIVE OUTCOME ACTIVITIES
    -- Process relevance: These represent process failures or interruptions
    -- Critical for identifying problematic process paths and bottlenecks
    -- ========================================================================
    
    -- INCOMPLETE PASSES: Failed passing attempts (different from successful passes)
    WHEN play_type = 'pass' AND desc LIKE '%incomplete%' THEN 'incomplete pass'
    
    -- QUARTERBACK SACKS: Defensive disruption of passing process
    WHEN desc LIKE '%sacked%' THEN 'sacked'
    
    -- TURNOVERS: Critical process failure events that terminate drives
    WHEN interception = 1 THEN 'interception'
    WHEN fumble = 1 THEN 'fumble'
    
    -- SUCCESSFUL OUTCOMES: Touchdown scoring plays (ultimate process success)
    WHEN touchdown = 1 THEN 'touchdown'
    
    -- ========================================================================
    -- PROCESS DISRUPTION EVENTS
    -- These activities represent interruptions or administrative events
    -- Important for understanding process flow irregularities
    -- ========================================================================
    
    -- PENALTIES: Rule violations that disrupt normal process flow
    WHEN desc LIKE '%penalty%' THEN 'offensive penalty'
    
    -- ADMINISTRATIVE: Plays that don't advance the process (often due to penalties)
    WHEN desc LIKE '%no play%' THEN 'no play'
    
    -- TEMPORAL BOUNDARIES: Game structure events that end process instances
    WHEN desc LIKE '%end of half%' THEN 'end of half'
    WHEN desc LIKE '%end of game%' THEN 'end of game'
    
    -- ========================================================================
    -- DEFAULT FALLBACK
    -- Ensures all activities are classified, preventing NULL values in process log
    -- ========================================================================
    ELSE play_type
END;

-- ============================================================================
-- STEP 5: TEMPORAL TRANSFORMATION - CREATE PROCESS MINING TIMESTAMPS
-- ============================================================================
-- PROCESS MINING RATIONALE: Process mining algorithms require proper temporal
-- ordering of activities within each case. NFL timing data needs transformation
-- to create sequential timestamps that represent process progression.
--
-- TECHNICAL APPROACH: Convert quarter_seconds_remaining to elapsed time format
-- that maintains proper chronological ordering for process analysis.

ALTER TABLE cleaned_dataset
ADD COLUMN transformed_time VARCHAR(20);

-- TIMESTAMP TRANSFORMATION LOGIC:
-- 1. NFL quarters are 15 minutes (900 seconds) each
-- 2. quarter_seconds_remaining counts DOWN from 900 to 0
-- 3. We convert to elapsed time by calculating (3599 - quarter_seconds_remaining)
-- 4. Format as HH:MM:SS for process mining tool compatibility
-- 5. Use arbitrary date (2000-01-01) since only time ordering matters for process analysis

UPDATE cleaned_dataset
SET transformed_time = 
    '01/01/2000 ' || 
    printf('%02d:%02d:%02d', 
           0,  -- Hours (always 0 for single game analysis)
           (3599 - quarter_seconds_remaining) / 60,    -- Minutes elapsed
           (3599 - quarter_seconds_remaining) % 60);   -- Seconds component

-- ============================================================================
-- STEP 6: FINAL EVENT LOG CONSTRUCTION - CREATE PROCESS MINING OUTPUT
-- ============================================================================
-- PROCESS MINING RATIONALE: Construct the final event log with proper column
-- ordering for process mining tools. Lead with the essential process mining
-- attributes (case_id, activity_name, timestamp) followed by enrichment data.
--
-- OUTPUT FORMAT: Optimized for PM4PY and other process mining tools while
-- preserving rich contextual data for advanced analysis.

CREATE TABLE final_cleaned_dataset AS
SELECT 
    -- ========================================================================
    -- CORE PROCESS MINING ATTRIBUTES (Required for all process mining tools)
    -- ========================================================================
    case_id,           -- Unique process instance identifier
    activity_name,     -- Mapped process activity label  
    transformed_time,  -- Chronological timestamp for activity ordering
    
    -- ========================================================================
    -- CONTEXTUAL ATTRIBUTES (Enrich process analysis with domain knowledge)
    -- ========================================================================
    game_id,           -- Game context for process instance grouping
    drive,             -- Drive number within game
    play_type,         -- Original activity classification
    time,              -- Original NFL timestamp format
    
    -- Strategic context for advanced process analysis
    pass_length,
    pass_location,
    run_location,
    run_gap,
    
    -- Outcome attributes for performance analysis
    field_goal_result,
    extra_point_result,
    two_point_conv_result,
    touchdown,
    interception,
    fumble,
    
    -- Descriptive and situational context
    desc,              -- Original play description
    down,              -- Game situation context
    yards_gained,      -- Activity outcome measurement
    quarter_seconds_remaining, -- Original timing data
    posteam,           -- Organizational unit
    
    -- ========================================================================
    -- CASE-LEVEL ATTRIBUTES (Enable process outcome analysis)
    -- ========================================================================
    drive_touchdown,   -- Did this process instance result in touchdown?
    drive_field_goal,  -- Did this process instance result in field goal?
    drive_any_score,   -- Did this process instance result in any scoring?
    drive_turnover,    -- Did this process instance end in turnover?
    
    -- ========================================================================
    -- RESOURCE ATTRIBUTES (Optional: Enable resource-based process analysis)
    -- ========================================================================
    passer,            -- Personnel resource for passing activities
    receiver,          -- Target resource for passing activities
    runner             -- Personnel resource for rushing activities
    
FROM cleaned_dataset;

/*
================================================================================
TRANSFORMATION COMPLETE

The resulting final_cleaned_dataset table contains a process mining event log with:
- Case ID: Unique identifier for each offensive drive (process instance)
- Activity: Strategic play classifications preserving NFL decision context
- Timestamp: Properly ordered temporal progression within each drive
- Enrichment: Case-level outcomes and contextual attributes

This event log is ready for import into process mining tools like PM4PY, ProM,
Celonis, or other process analysis platforms.

Key Process Mining Capabilities Enabled:
- Process Discovery: Identify common play-calling patterns and strategies
- Conformance Checking: Compare actual vs. expected offensive game plans
- Performance Analysis: Correlate process paths with drive success outcomes
- Variant Analysis: Compare different types of drives (scoring vs. non-scoring)
- Resource Analysis: Study personnel usage patterns in different situations

================================================================================
*/