# ModelValidation
Model validation for DAX measures


This is in progress and may not be fully functional.

The tool will validate your current model against validated numbers stored in a CSV. It is written in PowerShell as I hope to integrate into a DevOps pipeline.


The validation file should be a csv with the headers:
-ID
-Measure
-Value

ID is a reference. Measure should be the measure validating. Value is the validated value.
The remaining columns should be in format table9coulmn0 e.g. Product[Category]
Fill in the values for a filter or leave blank to not apply filter.

Example:
ID	Measure	Value	Product[Category]	Salesperson[Name]
1	Total Sales	552174	Consulting	Belle
2	Total Sales	966000	Consulting	Eli
3	Total Sales	5499025	Consulting	
4	Last Year Sales	3037053		Loki
![image](https://user-images.githubusercontent.com/68716422/119565427-8a0c1800-bd6f-11eb-8c61-e2fa2b85bd2c.png)
