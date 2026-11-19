"""Map for the St. Lawrence screen. Usage: edit S to your Natural Earth folder, then python3 python/st_lawrence_map.py"""
import geopandas as gpd, pandas as pd, matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt, warnings; warnings.filterwarnings('ignore')
S='/tmp/claude-0/-home-claude/0fbc8e62-ca92-5ab2-a790-43caebffdfdc/scratchpad/'
R='/home/claude/matlab_shipping_gis/outputs/'
c=gpd.read_file(S+'ne/ne_10m_admin_0_countries_lakes.shp').cx[-75:-64,43:50]
z=gpd.read_file(R+'2024_2025/shipping_zone_2024_2025_ships_100km_land.shp').to_crs(4326).cx[-75:-64,43:50]
s=pd.read_csv(R+'foreign_waterways/st_lawrence_source_cells_rev1.csv')
fig,ax=plt.subplots(figsize=(7,6),dpi=150)
c.plot(ax=ax,color='#EDEDED',edgecolor='#8A8D91',lw=0.5)
z.plot(ax=ax,color='#BFC9E8',edgecolor='none')
ax.scatter(s.lon,s.lat,s=0.4,c='#5674C4',label='DFO cargo and tanker cells (26 or more tracks a year)')
from shapely.geometry import box
ax.set_xlim(-74.5,-66.5); ax.set_ylim(44.5,49.3); ax.set_aspect(1/0.69)
ax.text(-69.3,46.0,'Maine',color='#1F2A44',fontsize=9); ax.text(-72.3,46.9,'Québec',color='#1F2A44',fontsize=9)
ax.text(-71.2,44.7,'Current 100 km zone (shaded)',color='#1F2A44',fontsize=8)
ax.set_title('St. Lawrence ships would add 5,200 to 5,600 km² of Maine to the 100 km zone',fontsize=10,loc='left')
ax.legend(loc='upper left',fontsize=7,frameon=False,markerscale=8); ax.set_xticks([]); ax.set_yticks([]); ax.set_xlabel(''); ax.set_ylabel('')
fig.text(0.01,0.01,'Source: DFO 2024 AIS vessel density (cargo + tanker); NTIA route cells 2024–2025; Natural Earth. DRAFT//PRE-DECISIONAL',fontsize=6,color='#1F2A44')
fig.savefig(R+'foreign_waterways/st_lawrence_screen_map_rev1.png'); print('ok')
