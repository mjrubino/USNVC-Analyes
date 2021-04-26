/*
	This query summarizes cell totals and calculates area in km2 across
	NVCS Groups by GAP PAD status (1, 2, 3, 4). It also includes the NVCS Class
	each Group belongs to in the NVCS hierarchy.
	First, it calculates the total number of cells in each Group. This is
	used to calculate the amount of cells that ARE NOT in status 1, 2, or 3
	lands. The calculation for the number of cells in a Group in status 4
	is INCORRECT because the PAD layer used to develop the analytic database
	has much of CONUS as NULL. To remedy this inconsistency, it is necessary
	to use the total cell count and subtract the cell sum for 1, 2, & 3 lands.
	Second, it calculates cell sums and km2 across Groups by status.
	Finally, it merges the two calculations into a single output.


	MJR 7 September 2018

*/


USE GAP_AnalyticDB;
GO


WITH

/*
	Summarization of total cells within each NVCS Group
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
	sum(lu_boundary_gap_landfire.count) as nCells,
	sum(lu_boundary_gap_landfire.count) * 0.0009 as km2
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


GO