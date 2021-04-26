/*

	National Vegetation Classification (NVC) land management
	summarization query using the GAP analytic database.
	
	This SQL query is used in a summarization for NVC categories across
	GAP Protected Areas Database (PAD) status levels - status 1, 2, 3 and 4.
	It utilizes an SQL server database assembled by intersecting numerous raster
	data layers created by the Gap Analysis Program including the PAD-US, species
	habitat maps, boundary layers such as states, counties, LCCs, ecoregions, etc.
	That database (the GAP Analytic database) at the time of this workflow
	development was only available on a local server. Hence, all code references
	a local instance of this database. This code is only replicable given access
	to a local instance of the database.

*/



USE GAP_AnalyticDB;
GO

WITH

/*
	Summarization of total cells within each land mangement type
*/

MangTotal AS (
SELECT 
	padus1_4.d_mang_nam,
	padus1_4.d_mang_typ
FROM     lu_boundary_gap_landfire INNER JOIN lu_boundary
			ON lu_boundary_gap_landfire.boundary = lu_boundary.value
			INNER JOIN padus1_4
			ON lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY  
	padus1_4.d_mang_typ,
	padus1_4.d_mang_nam
),

/*
	Summary for NVCS Classes by PAD Status (including NVC groups)
*/

NVC_Group AS (  
SELECT
	padus1_4.gap_sts as PADStatus,
	padus1_4.d_mang_nam as ManageName,
	padus1_4.d_mang_typ as ManageType,
	gap_landfire.nvc_class as NVCClass,
	gap_landfire.nvc_group as NVCGroup,
	sum(lu_boundary_gap_landfire.count) as nCells
FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON	lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON	lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON	lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.d_mang_nam,
  padus1_4.d_mang_typ,
  padus1_4.gap_sts, 
  gap_landfire.nvc_class,
  gap_landfire.nvc_group

)

/*
	Summarizing cell count by NVC Class, Management Name, and PAD Status
*/
	SELECT *
	FROM
	(
	SELECT NVC_Group.PADStatus,
			NVC_Group.NVCClass,
			NVC_Group.NVCGroup,
			NVC_Group.ManageName,
			NVC_Group.ManageType,
			SUM(NVC_Group.nCells) AS nCellSum
	FROM   MangTotal INNER JOIN NVC_Group 
		ON	   MangTotal.d_mang_nam = NVC_Group.ManageName
	GROUP BY NVC_Group.PADStatus,
			 NVC_Group.NVCClass,
			 NVC_Group.ManageType,
			 NVC_Group.NVCGroup,
			 NVC_Group.ManageName
	) AS NVC_Output

