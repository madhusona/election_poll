import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import ApexCharts from "apexcharts"

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content")

const destroyChart = (hook) => {
  if (hook.chart) {
    hook.chart.destroy()
    hook.chart = null
  }
}

const CandidateBarChart = {
  mounted() {
    this.renderChart()

    this.handleEvent("candidate_chart:update", ({ categories, series }) => {
      if (this.chart) {
        this.chart.updateOptions({
          xaxis: { categories: categories || [] }
        })
        this.chart.updateSeries([
          {
            name: "Votes",
            data: series || []
          }
        ])
      } else {
        this.renderChart(categories || [], series || [])
      }
    })
  },

  updated() {
    this.renderChart()
  },

  destroyed() {
    destroyChart(this)
  },

  renderChart(categories, series) {
    const labels =
      categories ||
      JSON.parse(this.el.dataset.categories || "[]")

    const values =
      series ||
      JSON.parse(this.el.dataset.series || "[]")

    destroyChart(this)

    this.chart = new ApexCharts(this.el, {
      chart: {
        type: "bar",
        height: 360,
        toolbar: { show: false }
      },
      series: [
        {
          name: "Votes",
          data: values
        }
      ],
      xaxis: {
        categories: labels
      },
      plotOptions: {
        bar: {
          horizontal: true,
          borderRadius: 6,
          barHeight: "58%",
          distributed: true
        }
      },
      dataLabels: {
        enabled: true
      },
      legend: {
        show: false
      },
      noData: {
        text: "No candidate data"
      }
    })

    this.chart.render()
  }
}

const GenderDonutChart = {
  mounted() {
    this.renderChart()

    this.handleEvent("gender_chart:update", ({ labels, series }) => {
      if (this.chart) {
        this.chart.updateOptions({ labels: labels || [] })
        this.chart.updateSeries(series || [])
      } else {
        this.renderChart(labels || [], series || [])
      }
    })
  },

  updated() {
    this.renderChart()
  },

  destroyed() {
    destroyChart(this)
  },

  renderChart(labels, series) {
    const finalLabels =
      labels ||
      JSON.parse(this.el.dataset.labels || "[]")

    const finalSeries =
      series ||
      JSON.parse(this.el.dataset.series || "[]")

    destroyChart(this)

    this.chart = new ApexCharts(this.el, {
      chart: {
        type: "donut",
        height: 320
      },
      labels: finalLabels,
      series: finalSeries,
      legend: {
        position: "bottom"
      },
      dataLabels: {
        enabled: true
      },
      noData: {
        text: "No gender data"
      }
    })

    this.chart.render()
  }
}

const AgeDonutChart = {
  mounted() {
    this.renderChart()

    this.handleEvent("age_chart:update", ({ labels, series }) => {
      if (this.chart) {
        this.chart.updateOptions({ labels: labels || [] })
        this.chart.updateSeries(series || [])
      } else {
        this.renderChart(labels || [], series || [])
      }
    })
  },

  updated() {
    this.renderChart()
  },

  destroyed() {
    destroyChart(this)
  },

  renderChart(labels, series) {
    const finalLabels =
      labels ||
      JSON.parse(this.el.dataset.labels || "[]")

    const finalSeries =
      series ||
      JSON.parse(this.el.dataset.series || "[]")

    destroyChart(this)

    this.chart = new ApexCharts(this.el, {
      chart: {
        type: "donut",
        height: 320
      },
      labels: finalLabels,
      series: finalSeries,
      legend: {
        position: "bottom"
      },
      dataLabels: {
        enabled: true
      },
      noData: {
        text: "No age group data"
      }
    })

    this.chart.render()
  }
}

const PartyDonutChart = {
  mounted() {
    this.renderChart()

    this.handleEvent("party_chart:update", ({ labels, series }) => {
      if (this.chart) {
        this.chart.updateOptions({ labels: labels || [] })
        this.chart.updateSeries(series || [])
      } else {
        this.renderChart(labels || [], series || [])
      }
    })
  },

  updated() {
    this.renderChart()
  },

  destroyed() {
    destroyChart(this)
  },

  renderChart(labels, series) {
    const finalLabels =
      labels ||
      JSON.parse(this.el.dataset.labels || "[]")

    const finalSeries =
      series ||
      JSON.parse(this.el.dataset.series || "[]")

    destroyChart(this)

    this.chart = new ApexCharts(this.el, {
      chart: {
        type: "donut",
        height: 320
      },
      labels: finalLabels,
      series: finalSeries,
      legend: {
        position: "bottom"
      },
      dataLabels: {
        enabled: true
      },
      noData: {
        text: "No party data"
      }
    })

    this.chart.render()
  }
}

const TrendLineChart = {
  mounted() {
    this.renderChart()

    this.handleEvent("trend_chart:update", ({ categories, series }) => {
      if (this.chart) {
        this.chart.updateOptions({
          xaxis: { categories: categories || [] }
        })
        this.chart.updateSeries([
          {
            name: "Votes",
            data: series || []
          }
        ])
      } else {
        this.renderChart(categories || [], series || [])
      }
    })
  },

  updated() {
    this.renderChart()
  },

  destroyed() {
    destroyChart(this)
  },

  renderChart(categories, series) {
    const finalCategories =
      categories ||
      JSON.parse(this.el.dataset.categories || "[]")

    const finalSeries =
      series ||
      JSON.parse(this.el.dataset.series || "[]")

    destroyChart(this)

    this.chart = new ApexCharts(this.el, {
      chart: {
        type: "line",
        height: 320,
        toolbar: { show: false }
      },
      series: [
        {
          name: "Votes",
          data: finalSeries
        }
      ],
      xaxis: {
        categories: finalCategories
      },
      stroke: {
        curve: "smooth",
        width: 3
      },
      dataLabels: {
        enabled: true
      },
      noData: {
        text: "No trend data"
      }
    })

    this.chart.render()
  }
}

const Hooks = {
  CandidateBarChart,
  GenderDonutChart,
  AgeDonutChart,
  PartyDonutChart,
  TrendLineChart
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })

window.addEventListener("phx:page-loading-start", () => topbar.show(300))
window.addEventListener("phx:page-loading-stop", () => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket