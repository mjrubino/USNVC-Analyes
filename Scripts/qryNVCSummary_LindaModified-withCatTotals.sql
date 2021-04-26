/*
	This is Linda Scheuck's code for summarizing cell counts across all NVC categories
	including Class, Subclass, Formation, Division, Macrogroup, Group, and Ecological System.
	
	Her code first joins the "lu_boundary_gap_landfire" table with the "padus1_4" table to
	generate a cell count summary and area measure of PAD statuses. Next, it joins the
	"lu_boundary" table with	the "lu_boundary_gap_landfire" table 7 times - once for each
	of the NVCS hierarchical categories - and joins each of those with the PAD status summary.
	Finally, it unions each	of the 7 summaries into a single output representing cell counts,
	area, and percent area for each PAD status and each NVCS category.

	I made changes by adding some documentation and changing output field names for clarity.
	I also changed the area calculation from acres to square kilometers.


	MJR 31 August 2018
	
	NOTE: This version tries to calculate total number of cells for each NVCS category
	and insert those values in a separate column for each of the category views that
	ultimately get unioned together. Its not correct and needs fixing.

*/


USE GAP_AnalyticDB;
GO


/*
	Summary across PAD statuses using NVCS/boundary intersection polygons.
	It totals cell counts for each PAD status as well as calculating a
	total area in km2 for the summed cells.
*/
WITH gap_sts_land as (
SELECT 
padus1_4.d_gap_sts, 
padus1_4.gap_sts,
SUM(lu_boundary_gap_landfire.count) AS gap_st_count, 
SUM(lu_boundary_gap_landfire.count) * 0.0009 AS total_PAD_km2
	FROM	lu_boundary_gap_landfire INNER JOIN lu_boundary
	ON		lu_boundary_gap_landfire.boundary = lu_boundary.value INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY 
padus1_4.d_gap_sts, 
padus1_4.gap_sts
),

/*
	Summary for NVCS Classes
*/
nvc_class as (  
SELECT  
padus1_4.gap_sts, 
padus1_4.d_gap_sts,
gap_landfire.cl, 
gap_landfire.nvc_class, 
SUM(lu_boundary_gap_landfire.count) AS nCells, 
SUM(lu_boundary_gap_landfire.count) * 0.0009 AS km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY gap_landfire.cl, 
gap_landfire.nvc_class, 
padus1_4.gap_sts, 
padus1_4.d_gap_sts
  ),
/*
	Summarization of total number of cells for each NVCS Class
*/
nvc_class_tot as (
SELECT 
gap_landfire.nvc_class,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_class
),

/*
	Summary for NVCS Subclasses
*/
nvc_subcl as (  
SELECT 
padus1_4.gap_sts, 
padus1_4.d_gap_sts, 
gap_landfire.sc, 
gap_landfire.nvc_subcl,
sum(lu_boundary_gap_landfire.count) as nCells,
sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  padus1_4.d_gap_sts, 
  gap_landfire.sc, 
  gap_landfire.nvc_subcl
  ),
/*
	Summarization of total number of cells for each NVCS Subclass
*/
nvc_subcl_tot as (
SELECT 
gap_landfire.nvc_subcl,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_subcl
),


/*
	Summary for NVCS Formations
*/
nvc_form as (  
SELECT 
padus1_4.gap_sts, 
padus1_4.d_gap_sts, 
gap_landfire.frm, 
gap_landfire.nvc_form,
sum(lu_boundary_gap_landfire.count) as nCells,
sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  padus1_4.d_gap_sts, 
  gap_landfire.frm, 
  gap_landfire.nvc_form
  ),
/*
	Summarization of total number of cells for each NVCS Formation
*/
nvc_form_tot as (
SELECT 
gap_landfire.nvc_form,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_form
),



/*
	Summary for NVCS Divisions
*/
nvc_div as (  
SELECT 
padus1_4.gap_sts, 
padus1_4.d_gap_sts, 
gap_landfire.div, 
gap_landfire.nvc_div,
sum(lu_boundary_gap_landfire.count) as nCells,
sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  padus1_4.d_gap_sts, 
  gap_landfire.div, 
  gap_landfire.nvc_div
  ),
/*
	Summarization of total number of cells for each NVCS Division
*/
nvc_div_tot as (
SELECT 
gap_landfire.nvc_div,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_div
),



/*
	Summary for NVCS Macrogroups
*/
nvc_macro as (  
SELECT 
padus1_4.gap_sts, 
padus1_4.d_gap_sts, 
gap_landfire.macro_cd, 
gap_landfire.nvc_macro,
sum(lu_boundary_gap_landfire.count) as nCells,
sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  padus1_4.d_gap_sts, 
  gap_landfire.macro_cd, 
  gap_landfire.nvc_macro
  ),
/*
	Summarization of total number of cells for each NVCS Macrogroup
*/
nvc_macro_tot as (
SELECT 
gap_landfire.nvc_macro,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_macro
),



/*
	Summary for NVCS Groups
*/
nvc_group as (  
SELECT 
padus1_4.gap_sts, 
padus1_4.d_gap_sts, 
gap_landfire.gr, 
gap_landfire.nvc_group,
sum(lu_boundary_gap_landfire.count) as nCells,
sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  padus1_4.d_gap_sts, 
  gap_landfire.gr, 
  gap_landfire.nvc_group
  ),
/*
	Summarization of total number of cells for each NVCS Group
*/
nvc_group_tot as (
SELECT 
gap_landfire.nvc_group,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_group
),


/*
	Summary for NVCS Ecological Systems
*/
nvc_ecosys as (  
SELECT 
padus1_4.gap_sts, 
padus1_4.d_gap_sts, 
gap_landfire.level3, 
gap_landfire.ecosys_lu,
sum(lu_boundary_gap_landfire.count) as nCells,
sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON		lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  padus1_4.d_gap_sts, 
  gap_landfire.level3, 
  gap_landfire.ecosys_lu
  ),
/*
	Summarization of total number of cells for each NVCS Ecological System
*/
nvc_ecosys_tot as (
SELECT 
gap_landfire.ecosys_lu,
sum(lu_boundary_gap_landfire.count) as nTotCatCells
	FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.ecosys_lu
) 



 /*
	Finish by compiling each of the NVC category summaries into
	separate summaries and unioning into a single appended output
 
 */   
SELECT * FROM (  

 SELECT 
   1 as level_code,
  'Class' as NVCS_Level,
  nvc_class.gap_sts as PAD_Status, 
  nvc_class.d_gap_sts as PAD_Status_Desc,
  CAST(nvc_class.cl AS varchar) as NVCS_Code, 
  nvc_class.nvc_class as NVCS_Name,
  nvc_class_tot.nTotCatCells,
  nvc_class.nCells,
  nvc_class.km2,
  nvc_class.km2/gap_sts_land.total_PAD_km2*100 AS percent_area_of_PAD_Status
  FROM 
  nvc_class,
  nvc_class_tot,
  gap_sts_land
  WHERE
  nvc_class.gap_sts = gap_sts_land.gap_sts
    
  UNION
  
  SELECT
    2 as level_code,
  'Subclass' as NVCS_Level,
  nvc_subcl.gap_sts as PAD_Status, 
  nvc_subcl.d_gap_sts as PAD_Status_Desc,
  nvc_subcl.sc  as NVCS_Code, 
  nvc_subcl.nvc_subcl as NVCS_Name,
  nvc_subcl_tot.nTotCatCells,
  nvc_subcl.nCells,
  nvc_subcl.km2,
  nvc_subcl.km2/gap_sts_land.total_PAD_km2*100 as percent_area_of_PAD_Status
  FROM 
  nvc_subcl,
  nvc_subcl_tot,
  gap_sts_land
  WHERE
  nvc_subcl.gap_sts = gap_sts_land.gap_sts
  
  UNION
  
  SELECT
    3 as level_code,
  'Formation' as NVCS_Level,
  nvc_form.gap_sts as PAD_Status, 
  nvc_form.d_gap_sts as PAD_Status_Desc,
  nvc_form.frm as NVCS_Code, 
  nvc_form.nvc_form as NVCS_Name,
  nvc_form_tot.nTotCatCells,
  nvc_form.nCells,
  nvc_form.km2,
  nvc_form.km2/gap_sts_land.total_PAD_km2*100 as percent_area_of_PAD_Status
  FROM 
  nvc_form,
  nvc_form_tot,
  gap_sts_land
  WHERE
  nvc_form.gap_sts = gap_sts_land.gap_sts
  
   
  UNION
  
  SELECT
    4 as level_code,
  'Division' as NVCS_Level,
  nvc_div.gap_sts as PAD_Status, 
  nvc_div.d_gap_sts as PAD_Status_Desc,
  nvc_div.div as NVCS_Code, 
  nvc_div.nvc_div as NVCS_Name,
  nvc_div_tot.nTotCatCells,
  nvc_div.nCells,
  nvc_div.km2,
  nvc_div.km2/gap_sts_land.total_PAD_km2*100 as percent_area_of_PAD_Status
  FROM 
  nvc_div,
  nvc_div_tot,
  gap_sts_land
  WHERE
  nvc_div.gap_sts = gap_sts_land.gap_sts
    
  UNION
  
  SELECT
    5 as level_code,
  'Macrogroup' as NVCS_Level,
  nvc_macro.gap_sts as PAD_Status, 
  nvc_macro.d_gap_sts as PAD_Status_Desc,
  nvc_macro.macro_cd as NVCS_Code, 
  nvc_macro.nvc_macro as NVCS_Name,
  nvc_macro_tot.nTotCatCells,
  nvc_macro.nCells,
  nvc_macro.km2,
  nvc_macro.km2/gap_sts_land.total_PAD_km2*100 as percent_area_of_PAD_Status
  FROM 
  nvc_macro,
  nvc_macro_tot,
  gap_sts_land
  WHERE
  nvc_macro.gap_sts = gap_sts_land.gap_sts
  
    UNION
  
  SELECT
    6 as level_code,
  'Group' as NVCS_Level,
  nvc_group.gap_sts as PAD_Status, 
  nvc_group.d_gap_sts as PAD_Status_Desc,
  nvc_group.gr as NVCS_Code, 
  nvc_group.nvc_group as NVCS_Name,
  nvc_group_tot.nTotCatCells,
  nvc_group.nCells,
  nvc_group.km2,
  nvc_group.km2/gap_sts_land.total_PAD_km2*100 as percent_area_of_PAD_Status
  FROM 
  nvc_group,
  nvc_group_tot,
  gap_sts_land
  WHERE
  nvc_group.gap_sts = gap_sts_land.gap_sts
 
     UNION
  
  SELECT
   7 as level_code,
  'Ecological System' as NVCS_Level,
  nvc_ecosys.gap_sts as PAD_Status, 
  nvc_ecosys.d_gap_sts as PAD_Status_Desc,
  CAST(nvc_ecosys.level3 as varchar) as NVCS_Code, 
  nvc_ecosys.ecosys_lu as NVCS_Name,
  nvc_ecosys_tot.nTotCatCells,
  nvc_ecosys.nCells,
  nvc_ecosys.km2,
  nvc_ecosys.km2/gap_sts_land.total_PAD_km2*100 as percent_area_of_PAD_Status
  FROM 
  nvc_ecosys,
  nvc_ecosys_tot,
  gap_sts_land
  WHERE
  nvc_ecosys.gap_sts = gap_sts_land.gap_sts

  ) as c
  ORDER BY 
  level_code, PAD_Status_Desc, NVCS_Code
