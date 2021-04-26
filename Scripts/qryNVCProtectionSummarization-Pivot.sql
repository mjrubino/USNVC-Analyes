/*

	National Vegetation Classification (NVC) land cover protection status
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
	Summarization of total cells within each NVCS GROUP
*/

NVC_GroupTotal AS (
SELECT 
	gap_landfire.nvc_group,
	sum(lu_boundary_gap_landfire.count) as nGroupTotalCells
FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON		lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON		lu_boundary.value = lu_boundary_gap_landfire.boundary
GROUP BY
  gap_landfire.nvc_group

),

/*
	Summary by PAD status for NVCS Groups
*/

NVC_Group AS (  
SELECT
	padus1_4.gap_sts as PADStatus, 
	gap_landfire.nvc_class as NVCClass,
	gap_landfire.nvc_group as NVCGroup,
	sum(lu_boundary_gap_landfire.count) as nCells
FROM	lu_boundary INNER JOIN lu_boundary_gap_landfire INNER JOIN gap_landfire
	ON	lu_boundary_gap_landfire.gap_landfire = gap_landfire.value
	ON	lu_boundary.value = lu_boundary_gap_landfire.boundary INNER JOIN padus1_4
	ON	lu_boundary.padus1_4 = padus1_4.objectid
GROUP BY
  padus1_4.gap_sts, 
  gap_landfire.nvc_class,
  gap_landfire.nvc_group

)

/*
	Assemblying data in single output and pivoting on status
*/
	SELECT *
	FROM
	(
	SELECT NVC_Group.PADStatus,
			NVC_Group.NVCClass,
			NVC_Group.NVCGroup,
			NVC_GroupTotal.nGroupTotalCells,
			NVC_Group.nCells
	FROM   NVC_GroupTotal INNER JOIN NVC_Group 
	ON	   NVC_GroupTotal.nvc_group = NVC_Group.NVCGroup
	) AS NVC_Output

	PIVOT
	(
		MAX(NVC_Output.nCells)
		FOR NVC_Output.PADStatus IN ([1], [2], [3], [4])
	) piv
	ORDER BY NVCGroup
