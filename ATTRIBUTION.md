# Data Attribution and Credits

## Primary Data Source

This project uses data from the **nflverse** ecosystem, a comprehensive collection of NFL data and analytics tools maintained by the open source sports analytics community.

### nflverse Project
- **Website**: https://www.nflverse.com/
- **GitHub Organization**: https://github.com/nflverse
- **Main Data Repository**: https://github.com/nflverse/nflverse-data

### Specific Dataset Used
- **Dataset**: 2007 NFL Play-by-Play Data
- **Source URL**: https://github.com/nflverse/nflverse-data/releases/download/pbp/play_by_play_2007.csv
- **Data License**: Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Original Data Provider**: NFL via various official sources, cleaned and standardized by nflverse

## Key Contributors to nflverse

We acknowledge the significant contributions of the nflverse community, particularly:

- **Sebastian Carl** (@mrcaseb) - Core maintainer and data engineering
- **Ben Baldwin** (@guga31bb) - Statistical methodology and nflfastR development  
- **Tan Ho** (@tanho63) - R package development and data infrastructure
- **Lee Sharpe** - Original NFL data compilation and cleaning methodology
- **Saiem Gilani** (@saiemgilani) - Python package development (nflreadpy)

## Data Processing and Enhancement

The nflverse data represents substantial processing work beyond the original NFL sources:

### Data Enhancements by nflverse
- **Expected Points Added (EPA)** calculations
- **Win Probability Added (WPA)** modeling  
- **Player identification and standardization**
- **Play classification and categorization**
- **Situational context variables**
- **Data quality improvements and error correction**

### Technical Infrastructure
- **Automated data pipelines** for regular updates
- **Multiple format availability** (CSV, Parquet, RDS, QS)
- **Version control and release management**
- **Comprehensive documentation and examples**

## Our Contribution

This repository contributes:

### Process Mining Transformation Methodology
- **SQL-based transformation pipeline** from NFL data to process mining event logs
- **Strategic activity classification** preserving NFL tactical context
- **Case identification logic** defining drives as process instances
- **Temporal transformation** for process mining compatibility

### Educational Value
- **Comprehensive documentation** explaining transformation rationale
- **Reproducible execution pipeline** for learning and extension
- **Domain expertise application** demonstrating data science methodology
- **Professional code organization** following data engineering best practices

## License Compliance

### nflverse Data License
The original nflverse data is provided under **Creative Commons Attribution 4.0 International License**.

**Requirements met:**
- ✅ **Attribution**: This file provides comprehensive credit to nflverse and contributors
- ✅ **Indicate Changes**: Our transformations are clearly documented and distinct from source data
- ✅ **License Notice**: CC BY 4.0 license is explicitly mentioned and linked
- ✅ **No Additional Restrictions**: Our GPL-3.0 license is compatible and adds no restrictions to the data

### Our Code License
Our transformation code and methodology are provided under **GNU General Public License v3.0**.

## Recommended Citation

If you use this work in academic or professional contexts, please cite both the original nflverse data and our methodology:

### nflverse Data Citation
```
Carl, S., Baldwin, B., Ho, T., Sharpe, L., Gilani, S., and the nflverse community (2024). 
nflverse-data: Open Source NFL Data. https://github.com/nflverse/nflverse-data
```

### This Project Citation  
```
Blackbourn, N. (2025). NFL Process Mining: From Play-by-Play to Event Log. 
https://github.com/nickblackbourn/nfl-process-mining
```

## Support the nflverse Project

The nflverse project relies on community support and contributions:

- **GitHub**: Star and contribute to nflverse repositories
- **Discord**: Join the community at https://discord.com/invite/5Er2FBnnQa
- **Documentation**: Visit https://www.nflverse.com/ for comprehensive guides
- **Contribute**: Submit issues, improvements, or new functionality

## Disclaimer

This project is an independent educational tutorial and is not officially affiliated with the NFL, nflverse project, or any NFL teams. The data transformations and analysis represent our own methodology for educational and research purposes.

---

*Last updated: November 2025*