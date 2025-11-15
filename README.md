# NFL Process Mining: From Play-by-Play to Event Log

A comprehensive tutorial demonstrating how to transform NFL play-by-play data into process mining event logs using advanced SQL methodology. This repository showcases the complete pipeline from raw sports data to process-analyzable format, enabling strategic analysis of offensive drive patterns and success factors.

## 🎯 Learning Objectives

After working through this tutorial, you will understand:

- **Process Mining Fundamentals**: How to identify cases, activities, and timestamps in domain-specific data
- **Advanced SQL Transformations**: Sophisticated data engineering techniques for event log construction
- **Domain Expertise Application**: Strategic NFL knowledge applied to process activity classification
- **Data Engineering Best Practices**: Reproducible, scalable transformation pipelines

## 🏈 What This Repository Does

This project transforms NFL play-by-play data into a process mining event log by:

1. **Defining Process Boundaries**: Each NFL offensive drive becomes a distinct process instance (case)
2. **Strategic Activity Mapping**: Play types are classified with strategic context (e.g., "pass short left" vs. "run right tackle")
3. **Temporal Alignment**: Game timeline is converted to process mining compatible timestamps
4. **Outcome Enrichment**: Drive-level results enable analysis of which process paths lead to scoring

**Input**: 43,000+ NFL plays from 2007 season (nflverse data)  
**Output**: Process mining event log ready for PM4PY, ProM, or Celonis analysis

## 🚀 Quick Start

### Prerequisites
- Python 3.8 or higher
- Internet connection (for downloading nflverse data)

### Installation & Execution

```bash
# Clone the repository
git clone https://github.com/nickblackbourn/nfl-process-mining.git
cd nfl-process-mining

# Install dependencies
pip install -r requirements.txt

# Run the complete transformation pipeline
python run_transformation.py
```

That's it! The script will:
- Download 2007 NFL play-by-play data from nflverse
- Execute the SQL transformation pipeline
- Validate the results
- Export `outputs/nfl_eventlog.csv` ready for process mining

## 📊 Output Format

The resulting event log contains:

**Core Process Mining Columns:**
- `case_id`: Unique drive identifier (e.g., "2007_01_NE_NYJ_1")
- `activity_name`: Strategic play classification (e.g., "pass short left", "run right tackle")
- `transformed_time`: Process mining timestamp (chronological ordering)

**Enrichment Columns:**
- `drive_any_score`: Did this drive result in points? (process outcome)
- `yards_gained`: Activity outcome measurement
- `down`, `desc`: Situational context
- Plus 20+ additional NFL context attributes

## 🧠 Methodology Deep Dive

### Process Mining Design Decisions

**Why Drives as Cases?**  
An NFL offensive drive represents one complete execution of the "offensive possession" process - from gaining possession to either scoring, turning over the ball, or reaching a natural stopping point (end of half/game). This creates meaningful process boundaries for analysis.

**Why Strategic Activity Classification?**  
Simple classifications like "run" vs. "pass" lose critical strategic context. Our sophisticated mapping preserves decision-making nuance:
- `pass short left` vs `pass deep middle` represent different strategic choices
- `run left tackle` vs `run right end` show distinct tactical executions
- Outcome-specific activities like `sacked` and `interception` capture process failures

**Why This SQL Approach?**  
The transformation uses advanced SQL techniques that demonstrate:
- Proper data engineering methodology (intermediate tables, clear steps)
- Scalable approach suitable for production environments  
- Complex domain logic handling with sophisticated CASE statements
- Professional ETL patterns for process mining transformations

## 🔬 Analysis Possibilities

With this event log, you can perform:

**Process Discovery**: Identify common play-calling patterns and sequences  
**Conformance Checking**: Compare actual vs. expected offensive strategies  
**Performance Analysis**: Correlate process paths with drive success rates  
**Variant Analysis**: Compare different types of drives (scoring vs. non-scoring)  
**Resource Analysis**: Study personnel usage in different game situations  

## 📁 Repository Structure

```
nfl-process-mining/
├── README.md                  # This comprehensive guide
├── ATTRIBUTION.md            # nflverse data credits and sources
├── run_transformation.py     # Single-command execution script
├── requirements.txt          # Python dependencies
├── src/
│   └── transform_data.sql    # Heavily commented SQL transformation
├── data/                     # (Data downloaded automatically)
├── outputs/
│   └── nfl_eventlog.csv     # Final process mining event log
└── .gitignore               # Excludes large data files
```

## 🎓 Educational Value

This repository serves as a comprehensive example of:

- **Advanced SQL for Data Science**: Complex transformations with clear business logic
- **Process Mining Methodology**: Proper event log construction from domain data  
- **Data Engineering Best Practices**: Reproducible, documented, scalable pipelines
- **Domain Expertise Application**: Strategic knowledge driving technical decisions

Perfect for data scientists learning process mining, SQL practitioners seeking advanced techniques, or sports analytics enthusiasts interested in strategic analysis.

## 📈 Next Steps

1. **Explore the SQL**: Read `src/transform_data.sql` to understand the transformation methodology
2. **Analyze the Results**: Import `outputs/nfl_eventlog.csv` into your process mining tool
3. **Extend the Analysis**: Modify the SQL to include additional teams or seasons
4. **Apply the Methodology**: Use this approach as a template for other domain transformations

## 🤝 Contributing

Found an improvement or have a question? Open an issue or submit a pull request. This repository aims to be a learning resource for the community.

## 📜 License

GNU General Public License v3.0 - see [LICENSE](LICENSE) file for details.
