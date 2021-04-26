# -*- coding: utf-8 -*-
"""
Created on Wed Sep  5 14:22:10 2018

@author: mjrubino
"""

'''@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



        NVCSummarization.py
        
        Uses GAP Analytic database to summarize protection across
        National Vegetation Classification Groups and Classes
        
        Output is a box plot of 5 NVC classes' percent mapped area
        by protection status (GAP status 1 & 2 and GAP status 1-3).


 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'''

import pyodbc, pandas as pd
import pandas.io.sql as psql
import seaborn as sns
import matplotlib.pyplot as plt


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#            ++++ Directory Locations ++++



#############################################################################################
################################### LOCAL FUNCTIONS #########################################
#############################################################################################


## --------------Cursor and Database Connections--------------------

def ConnectToDB(connectionStr):
    '''
    (str) -> cursor, connection

    Provides a cursor within and a connection to the database

    Argument:
    connectionStr -- The SQL Server compatible connection string
        for connecting to a database
    '''
    try:
        con = pyodbc.connect(connectionStr)
    except:
        connectionStr = connectionStr.replace('11.0', '10.0')
        con = pyodbc.connect(connectionStr)

    return con.cursor(), con

## ----------------Database Connection----------------------

def ConnectAnalyticDB():
    '''
    Returns a cursor and connection within the GAP analytic database.
    '''
    # Database connection parameters
    dbConStr = """DRIVER=SQL Server Native Client 11.0;
                    SERVER=CHUCK\SQL2014;
                    UID=;
                    PWD=;
                    TRUSTED_CONNECTION=Yes;
                    DATABASE=GAP_AnalyticDB;"""

    return ConnectToDB(dbConStr)


#############################################################################################
#############################################################################################
#############################################################################################


## Connect to the Analytic Database
cur, conn = ConnectAnalyticDB()

## The SQL to pull out NVC Groups, Classes and PADUS data from the analytic db
sql = """

WITH

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

"""

# Make a dataframe from the results of the SQL query
df = psql.read_sql(sql, conn)

# Fill all the empty values with 0 and rename columns
df['PAD1'] = df['1'].fillna(0)
df['PAD2'] = df['2'].fillna(0)
df['PAD3'] = df['3'].fillna(0)


# Drop the original PAD status columns
df = df.drop('1', axis=1)
df = df.drop('2', axis=1)
df = df.drop('3', axis=1)
df = df.drop('4', axis=1)


# Recalcute PAD status 4 cell counts for NVC groups using the category
# totals and the sum of status 1 to 3 cell counts
df['PAD4'] = df['nGroupTotalCells'] - (df['PAD1'] + df['PAD2'] + df['PAD3'])

# Calculate area in km2
df['PAD1 km2'] = df['PAD1'] * 0.0009
df['PAD2 km2'] = df['PAD2'] * 0.0009
df['PAD3 km2'] = df['PAD3'] * 0.0009
df['PAD4 km2'] = df['PAD4'] * 0.0009


# Calculate percentages
df['% Protected 1 & 2'] = ((df['PAD1'] + df['PAD2'] ) / df['nGroupTotalCells']) * 100
df['% Protected 1, 2 & 3'] = ((df['PAD1'] + df['PAD2'] + df['PAD3']) / df['nGroupTotalCells']) * 100

# Examples of checking some stats
lt1 = len(df[df['% Protected 1 & 2'] < 1])
lt17 = len(df[(df['% Protected 1 & 2'] > 1) & (df['% Protected 1 & 2'] < 17)])
lt50 = len(df[(df['% Protected 1 & 2'] > 17) & (df['% Protected 1 & 2'] < 50)])
gt50 = len(df[df['% Protected 1 & 2'] > 50])
print('Number of NVC groups with less than 1 % protection = ', lt1)
print('Number of NVC groups with more than 1 % and less than 17% protection = ', lt17)
print('Number of NVC groups with more than 17 % and less than 50% protection = ', lt50)
print('Number of NVC groups with more than 50 % protection = ', gt50)

DsDlt1 = len(df[(df['% Protected 1 & 2'] < 1) & (df['NVCClass'] == 'Desert & Semi-Desert')])
print('Number of groups in Desert & Semi-desert class with less than 1% protection:', DsDlt1)
FWlt17 = len(df[(df['% Protected 1 & 2'] > 1) & (df['% Protected 1 & 2'] < 17) & (df['NVCClass'] == 'Forest & Woodland')])
print('Number of groups in Forest and Woodland class with less than 17% protection:', FWlt17)



'''

    Start manipulating the dataframe and
    plotting boxplots using the Seaborn package

'''
df2 = df[['NVCClass','NVCGroup','% Protected 1 & 2','% Protected 1, 2 & 3']]
# Pull out only the natural/non-anthropogenic NVC classes
df3 = df2[(df2['NVCClass'] == 'Forest & Woodland') | 
				(df2['NVCClass'] == 'Shrub & Herb Vegetation') | 
				(df2['NVCClass'] == 'Desert & Semi-Desert') | 
				(df2['NVCClass'] == 'Polar & High Montane Scrub, Grassland & Barrens') | 
				(df2['NVCClass'] == 'Open Rock Vegetation')]

# Re-orient the dataframe to generate boxplots for each NVC class
df3_melt = df3.melt(id_vars = 'NVCClass',
                  value_vars = ['% Protected 1 & 2',
                                '% Protected 1, 2 & 3'],
                  var_name = 'Percent Protected',
                  value_name = 'Percent of Mapped Area')

fig, ax = plt.subplots(figsize=(12,6))
plt.xticks(rotation=45)
a = sns.boxplot(data = df3_melt,
                hue = 'Percent Protected',
                x = 'NVCClass',
                y = 'Percent of Mapped Area',
                order = ['Forest & Woodland',
                         'Shrub & Herb Vegetation',
                         'Desert & Semi-Desert',
                         'Polar & High Montane Scrub, Grassland & Barrens',
                         'Open Rock Vegetation'],
                width=0.35,
                ax=ax)
a.set_xlabel('NVC Class', fontsize=12)
a.set_ylabel('Percent of Mapped Area', fontsize=12)
labels = ['F & W','S & H','D & SD','PHMS','ORV']
a.set_xticklabels(labels)
a.set_title('NVC Classes by Protection Status', fontsize=16)

plt.show()


"""
    Plot a horizontal bar chart for each NVC class showing
    the number of NVC groups in that class with 1 & 2 protection
    across all four protection % bins <1, 1-17, 17-50, >50
    
    To start, query the first dataframe for the necessary data
    and generate a new dataframe for plotting

"""

collist = ['NVCClass','LT1','LT17','LT50','GT50','nGroups']
tablelst = []
protcol = '% Protected 1 & 2'
classes = df3.NVCClass.unique()
for c in classes:
	n1 = len(df[(df[protcol] < 1) & (df['NVCClass'] == c)])
	n17 = len(df[(df[protcol] > 1) & (df[protcol] < 17) & (df['NVCClass'] == c)])
	n18 = len(df[(df[protcol] > 17) & (df[protcol] < 50) & (df['NVCClass'] == c)])
	n50 = len(df[(df[protcol] > 50) & (df['NVCClass'] == c)])
	nTotal = len(df[(df['NVCClass'] == c)])
	tablelst.append([c,n1,n17,n18,n50,nTotal])

dfProtBins = pd.DataFrame(tablelst, columns=collist)

fig2, ax = plt.subplots(figsize=(8,5))

# Plot each bar on top of the previous
# Plot total number of groups by class first
#sns.barplot(x="nGroups", y="NVCClass", data=dfProtBins,
#            label="Total Number of Groups", color="skyblue")

# Plot less than 17% protected numbers
sns.barplot(x="LT17", y="NVCClass", data=dfProtBins,
            label="< 17% Protected", color="orangered")

# Plot greater than 17% protected numbers			
sns.barplot(x="LT50", y="NVCClass", data=dfProtBins,
            label="17-50% Protected", color="y")

# Plot greater than 50% protected numbers
sns.barplot(x="GT50", y="NVCClass", data=dfProtBins,
            label="> 50% Protected", color="forestgreen")

# Plot less than 1% protected numbers
sns.barplot(x="LT1", y="NVCClass", data=dfProtBins,
            label="< 1% Protected", color="red")

# Add a legend and informative axis label
ax.legend(ncol=1, loc="lower right", frameon=True)
ax.set(xlim=(0, 100), ylabel="",
       xlabel="Number of NVC Groups in a Class By Protection Amount Category")
sns.despine(left=True, bottom=True)


"""
    Plot a vertical bar chart for the number of groups
    in protection categories by class

"""

cols = ['NVCClass','ProtCat','nGroups']
tablelst = []
protcol = '% Protected 1 & 2'
classes = df3.NVCClass.unique()
for c in classes:
	n1 = len(df[(df[protcol] < 1) & (df['NVCClass'] == c)])
	tablelst.append([c,'< 1%',n1])
	n17 = len(df[(df[protcol] > 1) & (df[protcol] < 17) & (df['NVCClass'] == c)])
	tablelst.append([c,'1-17%',n17])
	n18 = len(df[(df[protcol] > 17) & (df[protcol] < 50) & (df['NVCClass'] == c)])
	tablelst.append([c,'17-50%',n18])
	n50 = len(df[(df[protcol] > 50) & (df['NVCClass'] == c)])
	tablelst.append([c,'> 50%',n50])

dfProtCats = pd.DataFrame(tablelst, columns=cols)

fig3, ax3 = plt.subplots(figsize=(6,10))
plt.xticks(rotation=45)

ax3.set_xlabel('NVC Class', fontsize=12)
ax3.set_ylabel('Number of NVC Groups', fontsize=12)
labels = ['F & W','S & H','D & SD','PHMS','ORV']
ax3.set_xticklabels(labels)
ax3.set_title('Number of Groups in Protection Categories by Class', fontsize=16)
leg = ax3.legend()
leg.set_title('Protection Categories',prop={'size':11})

sns.barplot(data = dfProtCats,
                hue = 'ProtCat',
                x = 'NVCClass',
                y = 'nGroups',
                order = ['Forest & Woodland',
                         'Shrub & Herb Vegetation',
                         'Desert & Semi-Desert',
                         'Polar & High Montane Scrub, Grassland & Barrens',
                         'Open Rock Vegetation'],
                ax=ax3)








