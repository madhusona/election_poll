import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
//import { hooks as colocatedHooks } from "phoenix-colocated/election_poll"
import topbar from "../vendor/topbar"

import L from "leaflet"
// import "leaflet/dist/leaflet.css"
import "leaflet.heat"
import ApexCharts from "apexcharts"

const Hooks = {
  VoteHeatMap: {
    mounted() {
      this.mode = this.el.dataset.mode || "cluster"
      this.payload = this.getPoints()
  
      this.map = L.map(this.el).setView([12.9716, 77.5946], 10)
  
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: "&copy; OpenStreetMap contributors"
      }).addTo(this.map)
  
      this.layerGroup = L.layerGroup().addTo(this.map)
  
      this.renderMode(this.mode, this.payload)
  
      this.map.on("moveend", () => this.pushViewport())
      this.map.on("zoomend", () => this.pushViewport())
  
      this.handleEvent("update_map_layer", (data) => {
        this.mode = data.mode || "cluster"
        this.payload = data.payload || []
        this.renderMode(this.mode, this.payload)
      })
  
      setTimeout(() => this.pushViewport(), 200)
    },
  
    destroyed() {
      if (this.layerGroup) {
        this.layerGroup.clearLayers()
      }
  
      if (this.map) {
        this.map.remove()
      }
    },
  
    getPoints() {
      try {
        return JSON.parse(this.el.dataset.points || "[]")
      } catch (_e) {
        return []
      }
    },
  
    pushViewport() {
      if (!this.map) return
  
      const bounds = this.map.getBounds()
      const zoom = this.map.getZoom()
  
      this.pushEvent("map_view_changed", {
        north: bounds.getNorth(),
        south: bounds.getSouth(),
        east: bounds.getEast(),
        west: bounds.getWest(),
        zoom: zoom
      })
    },
  
    clearLayers() {
      if (this.layerGroup) {
        this.layerGroup.clearLayers()
      }
    },
  
    renderMode(mode, payload) {
      this.clearLayers()
  
      if (!payload || payload.length === 0) return
  
      if (mode === "cluster") {
        this.renderCandidateClusters(payload)
      } else {
        this.renderRawPoints(payload)
      }
    },
  
    renderCandidateClusters(clusters) {
      clusters.forEach((cluster) => {
        const south = parseFloat(cluster.south)
        const north = parseFloat(cluster.north)
        const west = parseFloat(cluster.west)
        const east = parseFloat(cluster.east)
        const centerLat = parseFloat(cluster.center_lat)
        const centerLng = parseFloat(cluster.center_lng)
    
        if (
          [south, north, west, east, centerLat, centerLng].some((v) => Number.isNaN(v))
        ) return
    
        const totalCount = parseInt(cluster.total_count || 0, 10)
        const majorityCount = parseInt(cluster.majority_count || 0, 10)
        const majorityColor = cluster.majority_color || "#2563eb"
        const majorityCandidate = cluster.majority_candidate || "Unknown"
        const breakdown = cluster.breakdown || []
    
        const bounds = [
          [south, west],
          [north, east]
        ]
    
        const rectangle = L.rectangle(bounds, {
          color: majorityColor,
          fillColor: majorityColor,
          fillOpacity: 0.35,
          weight: 1
        }).addTo(this.layerGroup)
    
        const labelIcon = L.divIcon({
          className: "cluster-count-label",
          html: `<div>${majorityCount}</div>`,
          iconSize: [40, 24],
          iconAnchor: [20, 12]
        })
    
        const labelMarker = L.marker([centerLat, centerLng], {
          icon: labelIcon,
          interactive: true
        }).addTo(this.layerGroup)
    
        const popupHtml = `
          <div style="min-width:220px">
            <div style="font-weight:700; margin-bottom:8px;">Cluster Summary</div>
            <div style="margin-bottom:6px;"><strong>Total Votes:</strong> ${totalCount}</div>
            <div style="margin-bottom:6px;"><strong>Leading Candidate:</strong> ${majorityCandidate}</div>
            <div style="margin-bottom:8px;"><strong>Leading Votes:</strong> ${majorityCount}</div>
            <hr style="margin:8px 0;" />
            ${breakdown.map((c) => `
              <div style="display:flex; align-items:center; gap:6px; margin-bottom:4px;">
                <span style="
                  display:inline-block;
                  width:10px;
                  height:10px;
                  border-radius:999px;
                  background:${c.color || "#2563eb"};
                "></span>
                <span>${c.name}: ${c.count}</span>
              </div>
            `).join("")}
          </div>
        `
    
        rectangle.bindPopup(popupHtml)
        labelMarker.bindPopup(popupHtml)
    
        rectangle.on("click", () => rectangle.openPopup())
        labelMarker.on("click", () => labelMarker.openPopup())
      })
    },
  
    renderRawPoints(points) {
      points.forEach((p) => {
        const lat = parseFloat(p.lat)
        const lng = parseFloat(p.lng)
  
        if (Number.isNaN(lat) || Number.isNaN(lng)) return
  
        const marker = L.circleMarker([lat, lng], {
          radius: 5,
          color: p.color || "#2563eb",
          fillColor: p.color || "#2563eb",
          fillOpacity: 0.85,
          weight: 1
        }).addTo(this.layerGroup)
  
        marker.bindPopup(`
          <div style="min-width: 160px">
            <div><strong>${p.candidate_name || "Candidate"}</strong></div>
            <div>${p.party_full_name || ""}</div>
            <div>Lat: ${lat}</div>
            <div>Lng: ${lng}</div>
          </div>
        `)
      })
    }
  },

  CandidateBarChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.candidate_stats || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        categories: stats.map((s) => s.candidate_name),
        series: stats.map((s) => s.votes),
        colors: stats.map((s) => s.color || "#2563eb")
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "bar",
          height: 350,
          toolbar: { show: false },
          animations: { enabled: true }
        },
        colors: data.colors,
        series: [
          {
            name: "Votes",
            data: data.series
          }
        ],
        xaxis: {
          categories: data.categories
        },
        dataLabels: {
          enabled: true
        },
        plotOptions: {
          bar: {
            borderRadius: 6,
            distributed: true
          }
        },
        legend: {
          show: false
        },
        yaxis: {
          title: {
            text: "Votes"
          }
        },
        noData: {
          text: "No votes yet"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        colors: data.colors,
        xaxis: {
          categories: data.categories
        }
      })

      this.chart.updateSeries([
        {
          name: "Votes",
          data: data.series
        }
      ])
    }
  },

  GenderDonutChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.gender_stats || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        labels: stats.map((s) => s.label),
        series: stats.map((s) => s.value)
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "donut",
          height: 350
        },
        labels: data.labels,
        series: data.series,
        legend: {
          position: "bottom"
        },
        noData: {
          text: "No data"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        labels: data.labels
      })

      this.chart.updateSeries(data.series)
    }
  },

  AgeDonutChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.age_stats || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        labels: stats.map((s) => s.label),
        series: stats.map((s) => s.value)
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "donut",
          height: 350
        },
        labels: data.labels,
        series: data.series,
        legend: {
          position: "bottom"
        },
        noData: {
          text: "No data"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        labels: data.labels
      })

      this.chart.updateSeries(data.series)
    }
  },

  PartyDonutChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.party_stats || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        labels: stats.map((s) => s.party),
        series: stats.map((s) => s.votes),
        colors: stats.map((s) => s.color || "#2563eb")
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "donut",
          height: 350
        },
        labels: data.labels,
        series: data.series,
        colors: data.colors,
        legend: {
          position: "bottom"
        },
        noData: {
          text: "No party data"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        labels: data.labels,
        colors: data.colors
      })

      this.chart.updateSeries(data.series)
    }
  },

  TrendLineChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.trend_stats || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        categories: stats.map((s) => s.time),
        series: stats.map((s) => s.votes)
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "line",
          height: 350,
          toolbar: { show: false },
          animations: { enabled: true }
        },
        stroke: {
          curve: "smooth",
          width: 3
        },
        series: [
          {
            name: "Votes",
            data: data.series
          }
        ],
        xaxis: {
          categories: data.categories
        },
        yaxis: {
          title: {
            text: "Votes"
          }
        },
        noData: {
          text: "No trend data"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        xaxis: {
          categories: data.categories
        }
      })

      this.chart.updateSeries([
        {
          name: "Votes",
          data: data.series
        }
      ])
    }
  },

  BoothTurnoutChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.booth_turnout_stats || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        categories: stats.map((s) => s.booth_name),
        series: stats.map((s) => s.votes)
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "bar",
          height: 300,
          toolbar: { show: false }
        },
        series: [
          {
            name: "Votes",
            data: data.series
          }
        ],
        xaxis: {
          categories: data.categories
        },
        dataLabels: {
          enabled: true
        },
        plotOptions: {
          bar: {
            borderRadius: 6
          }
        },
        noData: {
          text: "No booth data"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        xaxis: {
          categories: data.categories
        }
      })

      this.chart.updateSeries([
        {
          name: "Votes",
          data: data.series
        }
      ])
    }
  },

  BoothLeaderChart: {
    mounted() {
      const stats = this.getStats()
      this.renderChart(stats)

      this.handleEvent("update_charts", (data) => {
        this.updateFromData(data.booth_leaders || [])
      })
    },

    destroyed() {
      if (this.chart) this.chart.destroy()
    },

    getStats() {
      try {
        return JSON.parse(this.el.dataset.stats || "[]")
      } catch (_e) {
        return []
      }
    },

    normalize(stats) {
      return {
        categories: stats.map((s) => s.booth_name),
        series: stats.map((s) => s.votes),
        colors: stats.map((s) => s.color || "#2563eb")
      }
    },

    renderChart(stats) {
      const data = this.normalize(stats)

      this.chart = new ApexCharts(this.el, {
        chart: {
          type: "bar",
          height: 300,
          toolbar: { show: false }
        },
        colors: data.colors,
        series: [
          {
            name: "Leader Votes",
            data: data.series
          }
        ],
        xaxis: {
          categories: data.categories
        },
        plotOptions: {
          bar: {
            distributed: true,
            borderRadius: 6
          }
        },
        dataLabels: {
          enabled: true
        },
        legend: {
          show: false
        },
        noData: {
          text: "No booth leader data"
        }
      })

      this.chart.render()
    },

    updateFromData(stats) {
      const data = this.normalize(stats)

      if (!this.chart) {
        this.renderChart(stats)
        return
      }

      this.chart.updateOptions({
        colors: data.colors,
        xaxis: {
          categories: data.categories
        }
      })

      this.chart.updateSeries([
        {
          name: "Leader Votes",
          data: data.series
        }
      ])
    }
  }
}

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...Hooks }
})

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", () => topbar.show(300))
window.addEventListener("phx:page-loading-stop", () => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket

if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    reloader.enableServerLogs()

    let keyDown
    window.addEventListener("keydown", (e) => keyDown = e.key)
    window.addEventListener("keyup", () => keyDown = null)
    window.addEventListener("click", (e) => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
