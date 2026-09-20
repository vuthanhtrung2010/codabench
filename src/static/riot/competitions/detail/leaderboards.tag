<leaderboards>
    <div class="leaderboard-controls">
        <div class="ui left action input search-input">
            <button type="button" class="ui icon button" id="search-leaderboard-button">
                <i class="search icon"></i>
            </button>
            <input ref="leaderboardFilter" type="text" placeholder="Filter Leaderboard by Columns">
        </div>
        <a data-tooltip="Start typing to filter columns under 'Meta-data' or Tasks." data-position="right center">
            <i class="grey question circle icon"></i>
        </a>
        <div class="org-toggle-container">
            <a data-tooltip="Display organization name beneath each participant." data-position="bottom left">
                <i class="grey question circle icon"></i>
            </a>
            <div class="ui toggle checkbox" ref="show_org_checkbox">
                <input type="checkbox" ref="show_org_input" onchange="{ toggle_show_org }">
                <label>Show organization under each participant</label>
            </div>
        </div>
    </div>

    <table id="leaderboardTable" class="ui celled selectable sortable table">
        <thead>
        <tr>
            <th colspan="100%" class="center aligned">
                <p class="leaderboard-title">{ selected_leaderboard.title }</p>
                <div style="visibility:{show_download}" class="float-right">
                    <div class="ui compact menu">
                        <div class="ui simple dropdown item" style="padding: 0px 5px">
                            <i class="download icon" style="font-size: 1.5em; margin: 0;"></i>
                            <div style="padding-top: 8px; right: 0; left: auto;" class="menu">
                                <a href="{URLS.COMPETITION_GET_CSV(competition_id, selected_leaderboard.id)}" target="new" class="item">This CSV</a>
                                <a href="{URLS.COMPETITION_GET_JSON_BY_ID(competition_id, selected_leaderboard.id)}" target="new" class="item">This JSON</a>
                            </div>
                        </div>
                    </div>
                </div>
            </th>
        </tr>
        <tr class="task-row">
            <th>Task:</th>
            <th colspan="{ has_group_queues ? 4 : 3 }"></th>
            <th each="{ task in filtered_tasks }" class="center aligned" colspan="{ task.colWidth }">{ task.name }</th>
        </tr>
        <tr>
            <th class="center aligned">#</th>
            <th>Participant</th>
            <th class="center aligned">Date</th>
            <th class="center aligned">ID</th>
            <th if="{ has_group_queues }">Groups</th>
            <th each="{ column in filtered_columns }" colspan="1" class="{ (column.task_id != -1) ? 'center aligned' : '' } { column.is_total ? 'final-score-header' : '' }">{column.title}</th>
        </tr>
        </thead>
        <!--  Always show leaderboard  -->
        <tbody>
            <tr if="{_.isEmpty(paginated_submissions)}" class="center aligned">
                <td colspan="100%">
                    <em>No submissions have been added to this leaderboard yet!</em>
                </td>
            </tr>
            <tr each="{ submission, index in paginated_submissions}">
                <td class="collapsing index-column center aligned">
                    <award-badge if="{ get_award(get_row_number(index)) }"
                                 award="{ get_award(get_row_number(index)) }"
                                 type="{ (get_award(get_row_number(index)) || {}).type }"
                                 rank="{ (get_award(get_row_number(index)) || {}).rank }">
                    </award-badge>
                    <virtual if="{ !get_award(get_row_number(index)) }">{ get_row_number(index) }</virtual>
                </td>
                <td class="participant-col">
                    <a if="{submission.organization === null}" href="{submission.slug_url}">{ submission.owner }</a>
                    <a if="{submission.organization !== null}" href="{submission.organization.url}">{ submission.organization.name }</a>
                    <div if="{ show_org_under_participant && get_org_name(submission) }" class="card-org-subtext">
                        { get_org_name(submission) }
                    </div>
                </td>
                <td class="center aligned" data-sort="{ sort_date_value(submission.created_when) }"
                    data-sort-value="{ sort_date_value(submission.created_when) }">
                    { pretty_date(submission.created_when) }
                </td>
                <td class="center aligned">{submission.id}</td>
                <td if="{ has_group_queues }">
                    <span if="{ submission.queue_name }">{ submission.queue_name }</span>
                    <span if="{ !submission.queue_name }" class="ui grey text">—</span>
                </td>

                <td each="{ column in filtered_columns }"
                    class="{ (column.task_id != -1) ? 'center aligned score-cell' : '' } { column.is_total ? 'final-score-cell-col' : '' }"
                    data-sort="{ get_score_sort_value(column, submission) }"
                    data-sort-value="{ get_score_sort_value(column, submission) }">

                    <a if="{column.title == 'Detailed Results'}"
                    href="detailed_results/{get_detailed_result_submisison_id(column, submission)}"
                    target="_blank"
                    class="eye-icon-link">
                        <i class="icon grey eye eye-icon"></i>
                    </a>

                    <span if="{column.title != 'Detailed Results'}"
                        class="{bold_class(column, submission)}">
                        {get_score(column, submission)}
                        <small class="raw-score" if="{get_raw_score(column, submission) !== ''}">
                            raw {get_raw_score(column, submission)}
                        </small>
                    </span>
                </td>
            </tr>
        </tbody>
    </table>

    <!-- Mobile & Tablet Cards View -->
    <div class="leaderboard-cards" if="{ !_.isEmpty(paginated_submissions) }">
        <div class="leaderboard-card-header" if="{ selected_leaderboard.title }">
            <h4>{ selected_leaderboard.title }</h4>
        </div>
        <div class="leaderboard-card" each="{ submission, index in paginated_submissions }">
            <div class="card-award-banner">
                <award-badge if="{ get_award(get_row_number(index)) }"
                             award="{ get_award(get_row_number(index)) }"
                             type="{ (get_award(get_row_number(index)) || {}).type }"
                             rank="{ (get_award(get_row_number(index)) || {}).rank }">
                </award-badge>
                <span if="{ !get_award(get_row_number(index)) }" class="card-plain-rank">{ get_row_number(index) }</span>
            </div>

            <div class="card-row">
                <span class="card-label">Participant</span>
                <div class="card-value">
                    <a if="{submission.organization === null}" href="{submission.slug_url}" class="participant-link">{ submission.owner }</a>
                    <a if="{submission.organization !== null}" href="{submission.organization.url}" class="participant-link">{ submission.organization.name }</a>
                    <div if="{ show_org_under_participant && get_org_name(submission) }" class="card-org-subtext">
                        { get_org_name(submission) }
                    </div>
                </div>
            </div>

            <div class="card-row">
                <span class="card-label">Date</span>
                <span class="card-value card-date">{ pretty_date(submission.created_when) }</span>
            </div>

            <div class="card-row" if="{ !has_id_column() }">
                <span class="card-label">ID</span>
                <span class="card-value">{ submission.id }</span>
            </div>

            <div class="card-row" if="{ has_group_queues }">
                <span class="card-label">Groups</span>
                <span class="card-value">{ submission.queue_name || '—' }</span>
            </div>

            <div class="card-row { column.is_total ? 'card-final-score-row' : '' }"
                 each="{ column in filtered_columns }"
                 if="{ column.title != 'Detailed Results' }">
                <span class="card-label { column.is_total ? 'final-score-label' : '' }">{ column.title }</span>
                <div class="card-value { column.is_total ? 'final-score-value' : '' }">
                    <span class="{ bold_class(column, submission) }">{ get_score(column, submission) }</span>
                    <small class="raw-score" if="{ get_raw_score(column, submission) !== '' }">
                        raw { get_raw_score(column, submission) }
                    </small>
                </div>
            </div>

            <div class="card-row" if="{ enable_detailed_results && show_detailed_results_in_leaderboard }">
                <span class="card-label">Detailed Results</span>
                <div class="card-value">
                    <a each="{ column in filtered_columns }"
                       if="{ column.title == 'Detailed Results' }"
                       href="detailed_results/{ get_detailed_result_submisison_id(column, submission) }"
                       target="_blank"
                       class="ui mini button basic">
                        <i class="icon eye"></i> View
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="leaderboard-empty-cards center aligned" if="{ _.isEmpty(paginated_submissions) }">
        <em>No submissions have been added to this leaderboard yet!</em>
    </div>

    <div class="ui pagination menu pagination-container" style="display:flex; align-items:center; justify-content:space-between; margin-top: 12px;">
        <div style="display:flex; align-items:center; gap:8px;">
            <button class="ui button" onclick="{ go_to_page.bind(this, page - 1) }" disabled="{ page <= 1 }">
                <i class="icon chevron left"></i> Previous
            </button>
            <div style="display:flex; align-items:center; gap:6px;">
                <span>Page</span>
                <input type="number" min="1" value="{ page }" onkeydown="{ handle_page_enter }" style="width:70px; text-align:center;" />
                <span> / { total_pages || 1 }</span>
            </div>
            <button class="ui button" onclick="{ go_to_page.bind(this, page + 1) }" disabled="{ page >= total_pages }">
                Next <i class="icon chevron right"></i>
            </button>
        </div>
        <div style="display:flex; align-items:center; gap:8px;">
            <label>Per page</label>
            <select class="ui dropdown" value="{ page_size }" onchange="{ change_page_size.bind(this) }">
                <option value="50">50</option>
                <option value="100">100</option>
                <option value="500">500</option>
                <option value="all">all</option>
            </select>
            <div style="margin-right: 10px; color: #8c8c8c;">
                <small>{ total_count || 0 } total</small>
            </div>
        </div>
    </div>
    <script>
        let self = this
        self.selected_leaderboard = {}
        self.filtered_tasks = []
        self.columns = []
        self.filtered_columns = []
        self.phase_id = null
        self.competition_id = null
        self.enable_detailed_results = false
        self.show_detailed_results_in_leaderboard = false
        self.has_group_queues = false
        self.page = 1
        self.page_size = 50
        self.total_count = 0
        self.total_pages = 1
        self.paginated_submissions = []
        self.get_page_size_value = function () {
            if (String(self.page_size).toLowerCase() === 'all') {
                return self.total_count || 1
            }
            var n = parseInt(self.page_size, 10)
            if (isNaN(n) || n <= 0) {
                return 50
            }
            return n
        }
        self.get_row_number = function (index) {
            if (String(self.page_size).toLowerCase() === 'all') {
                return index + 1
            }
            return ((self.page - 1) * self.get_page_size_value()) + index + 1
        }
        self.update_pagination = function () {
            var submissions = _.get(self.selected_leaderboard, 'submissions', [])
            self.total_count = parseInt(_.get(self.selected_leaderboard, 'count', submissions.length), 10) || submissions.length
            var raw_page_size = _.get(self.selected_leaderboard, 'page_size', self.page_size)
            if (String(raw_page_size).toLowerCase() === 'all') {
                self.page_size = 'all'
                self.total_pages = 1
                self.page = 1
            } else {
                var page_size_value = parseInt(raw_page_size, 10)
                if (isNaN(page_size_value) || page_size_value <= 0) {
                    page_size_value = self.get_page_size_value()
                }
                self.page_size = page_size_value
                self.total_pages = Math.max(1, Math.ceil(self.total_count / page_size_value))
                if (self.page > self.total_pages) {
                    self.page = self.total_pages
                }
            }
            self.paginated_submissions = submissions
        }
        self.go_to_page = function (p) {
            if (String(self.page_size).toLowerCase() === 'all') {
                return
            }
            var newPage = parseInt(p, 10)
            if (isNaN(newPage) || newPage < 1) newPage = 1
            if (newPage > self.total_pages) newPage = self.total_pages
            if (newPage === self.page) return
            self.page = newPage
            self.update_leaderboard()
        }
        self.handle_page_enter = function (e) {
            if (e.key !== 'Enter' && e.keyCode !== 13) {
                return
            }
            e.preventDefault()
            self.go_to_page(e.target.value)
        }
        self.change_page_size = function (e) {
            var raw = (e && e.target && typeof e.target.value !== 'undefined')
                ? String(e.target.value).toLowerCase()
                : String(self.page_size).toLowerCase()
            if (raw === 'all') {
                self.page_size = 'all'
            } else {
                var val = parseInt(raw, 10)
                if (isNaN(val) || val <= 0) return
                if ([50, 100, 500].indexOf(val) === -1) return
                self.page_size = val
            }
            self.page = 1
            self.update_leaderboard()
        }
        self.pretty_date = function (date_string) {
            if (!!date_string) {
                return luxon.DateTime.fromISO(date_string).toFormat('yyyy-MM-dd HH:mm')
            } else {
                return ''
            }
        }
        self.sort_date_value = function (date_string) {
            if (!date_string) return 0
            const dt = luxon.DateTime.fromISO(date_string)
            return dt.isValid ? dt.toMillis() : 0
        }

        self.get_score_sort_value = function(column, submission) {
            if (column.task_id === -1) {
                let value = _.get(submission, 'fact_sheet_answers[' + column.key + ']')
                return (value !== null && typeof value !== 'undefined' && value !== '') ? value : ''
            }
            let score = _.get(_.find(submission.scores, {
                task_id: column.task_id,
                column_key: column.key
            }), 'score')
            return (score !== null && typeof score !== 'undefined' && score !== '') ? score : ''
        }

        self.show_org_under_participant = false
        self.toggle_show_org = function () {
            self.show_org_under_participant = $(self.refs.show_org_input).prop('checked') || self.refs.show_org_input.checked
            self.update()
        }
        self.get_org_name = function (submission) {
            if (!submission || !submission.organization) return ''
            if (typeof submission.organization === 'object') {
                return submission.organization.name || ''
            }
            return String(submission.organization)
        }
        self.has_id_column = function () {
            return _.some(self.filtered_columns, function (c) {
                var title = (c.title || '').toLowerCase()
                var key = (c.key || '').toLowerCase()
                return title === 'id' || key === 'id'
            })
        }
        self.get_award = function (rank) {
            if (!rank || rank < 1) return null
            var raw_has_trophy = (self.selected_leaderboard && typeof self.selected_leaderboard.has_trophy !== 'undefined')
                ? self.selected_leaderboard.has_trophy
                : true
            var has_trophy = (raw_has_trophy === false || raw_has_trophy === 'false' || raw_has_trophy === 0 || raw_has_trophy === '0')
                ? false
                : true

            var raw_gold = self.selected_leaderboard ? self.selected_leaderboard.medal_gold_count : undefined
            var gold_count = (typeof raw_gold !== 'undefined' && raw_gold !== null)
                ? parseInt(raw_gold, 10)
                : 1
            if (isNaN(gold_count) || gold_count < 0) gold_count = 0

            var raw_silver = self.selected_leaderboard ? self.selected_leaderboard.medal_silver_count : undefined
            var silver_count = (typeof raw_silver !== 'undefined' && raw_silver !== null)
                ? parseInt(raw_silver, 10)
                : 1
            if (isNaN(silver_count) || silver_count < 0) silver_count = 0

            var raw_bronze = self.selected_leaderboard ? self.selected_leaderboard.medal_bronze_count : undefined
            var bronze_count = (typeof raw_bronze !== 'undefined' && raw_bronze !== null)
                ? parseInt(raw_bronze, 10)
                : 1
            if (isNaN(bronze_count) || bronze_count < 0) bronze_count = 0

            var cur = 1
            if (has_trophy) {
                if (rank === 1) {
                    return { type: 'trophy', rank: 1 }
                }
                cur = 2
            }

            if (gold_count > 0 && rank >= cur && rank < cur + gold_count) {
                return { type: 'gold', rank: rank }
            }
            cur += gold_count

            if (silver_count > 0 && rank >= cur && rank < cur + silver_count) {
                return { type: 'silver', rank: rank }
            }
            cur += silver_count

            if (bronze_count > 0 && rank >= cur && rank < cur + bronze_count) {
                return { type: 'bronze', rank: rank }
            }

            return null
        }

        self.bold_class = function(column, submission){
            if (column.is_total === true) {
                return 'total-score-cell'
            }
            return 'text-bold'
        }
        self.get_score = function(column, submission) {
            if (column.is_total) {
                let sum = 0
                let has_score = false
                for (let lc of (column.last_columns || [])) {
                    let score = _.get(
                        _.find(submission.scores, { task_id: lc.task_id, column_key: lc.key }),
                        'score'
                    )
                    if (score !== undefined && score !== null && score !== '') {
                        sum += parseFloat(score)
                        has_score = true
                    }
                }
                return has_score ? sum.toFixed(2) : ''
            }
            if(column.task_id === -1){
                return _.get(submission, 'fact_sheet_answers[' + column.key + ']', 'n/a')
            } else {
                let score = _.get(_.find(submission.scores, {'task_id': column.task_id, 'column_key': column.key}), 'score')
                if (score !== null && typeof score !== 'undefined' && score !== '') {
                    return score
                }
            }
            return 'n/a'
        }
        self.get_raw_score = function(column, submission) {
            if (_.get(self.selected_leaderboard, 'show_raw_scores') === false) {
                return ''
            }
            if (column.is_total) {
                let sum = 0
                let has_score = false
                for (let lc of (column.last_columns || [])) {
                    let raw = _.get(
                        _.find(submission.scores, { task_id: lc.task_id, column_key: lc.key }),
                        'raw_score'
                    )
                    if (raw !== undefined && raw !== null && raw !== '') {
                        sum += parseFloat(raw)
                        has_score = true
                    }
                }
                return has_score ? sum.toFixed(2) : ''
            }
            if (column.task_id === -1 || column.task_id === '__total__') {
                return ''
            }
            let score_obj = _.find(submission.scores, {'task_id': column.task_id, 'column_key': column.key})
            if (!score_obj) {
                return ''
            }
            let raw = _.get(score_obj, 'raw_score')
            if (raw !== undefined && raw !== null && raw !== '') {
                return raw
            }
            return ''
        }
        self.on("mount", function () {
            this.refs.leaderboardFilter.onkeyup = function (e) {
                self.filter_columns()
            }
            $('#search-leaderboard-button').click(function() {
                $(self.refs.leaderboardFilter).focus()
            })
            $(self.refs.show_org_checkbox).checkbox({
                onChange: function () {
                    self.show_org_under_participant = self.refs.show_org_input.checked
                    self.update()
                }
            })
            $('#leaderboardTable').tablesort()
        })
        self.filter_columns = () => {
            let search_key = self.refs.leaderboardFilter.value.toLowerCase()
            self.filtered_tasks = JSON.parse(JSON.stringify(self.selected_leaderboard.tasks || []))
            if (search_key) {
                self.filtered_columns = []
                for (const column of self.columns) {
                    let key = (column.key || '').toLowerCase()
                    let title = (column.title || '').toLowerCase()
                    if ((key.includes(search_key) || title.includes(search_key))) {
                        self.filtered_columns.push(column)
                    } else {
                        let task = _.find(self.filtered_tasks, {id: column.task_id})
                        if (task) task.colWidth -= 1
                    }
                }
                self.filtered_tasks = self.filtered_tasks.filter(task => task.colWidth > 0)
            } else {
                self.filtered_columns = self.columns
            }
            self.update()
        }
        self.ws = null
        self.is_tab_visible = false

        self.update_leaderboard = () => {
            if (!self.phase_id) {
                return
            }
            CODALAB.api.get_leaderboard_for_render(self.phase_id, {
                page: self.page,
                page_size: self.page_size
            })
            .done(responseData => {
                self.selected_leaderboard = responseData
                self.has_group_queues = responseData.has_group_queues || false
                self.available_queues = responseData.available_queues || []
                self.columns = []

                if (self.selected_leaderboard.fact_sheet_keys) {
                    let fake_metadata_task = {
                        id: -1,
                        colWidth: self.selected_leaderboard.fact_sheet_keys.length,
                        columns: [],
                        name: "Fact Sheet Answers"
                    }

                    for (let question of self.selected_leaderboard.fact_sheet_keys) {
                        fake_metadata_task.columns.push({
                            key: question[0],
                            title: question[1],
                        })
                    }

                    self.selected_leaderboard.tasks.unshift(fake_metadata_task)
                }

                for (let task of self.selected_leaderboard.tasks) {
                    if (self.available_queues.length > 0) {
                        for (let queue_name of self.available_queues) {
                            for (let column of task.columns) {
                                let clonedColumn = Object.assign({}, column)
                                clonedColumn.task_id = task.id
                                clonedColumn.queue_name = queue_name
                                clonedColumn.title = `${column.title} (${queue_name})`
                                self.columns.push(clonedColumn)
                            }
                        }
                    } else {
                        for (let column of task.columns) {
                            let clonedColumn = Object.assign({}, column)
                            clonedColumn.task_id = task.id
                            self.columns.push(clonedColumn)
                        }
                    }

                    if (self.enable_detailed_results && self.show_detailed_results_in_leaderboard && task.id != -1) {
                        self.columns.push({
                            task_id: task.id,
                            title: "Detailed Results"
                        })
                        task.colWidth += 1
                    }
                }

                let valid_tasks = (self.selected_leaderboard.tasks || []).filter(t => t.id !== -1 && t.id !== '__total__')
                if (valid_tasks.length > 1 && !_.some(self.columns, c => c.is_total || c.key === '__total__')) {
                    let last_columns = []
                    for (let task of valid_tasks) {
                        if (task.columns && task.columns.length > 0) {
                            let last_col = task.columns[task.columns.length - 1]
                            last_columns.push({ task_id: task.id, key: last_col.key })
                        }
                    }
                    if (last_columns.length > 1) {
                        let total_task = {
                            id: '__total__',
                            name: 'SUMMARY',
                            colWidth: 1,
                            columns: [{ key: '__total__', title: 'FINAL SCORE', task_id: '__total__', is_total: true, last_columns: last_columns }]
                        }
                        self.selected_leaderboard.tasks.push(total_task)
                        self.columns.push(total_task.columns[0])
                    }
                }

                self.filter_columns()
                self.update_pagination()
                $('#leaderboardTable').tablesort()
                self.update()
            })
        }

        self.debounced_update_leaderboard = _.debounce(() => {
            self.update_leaderboard()
        }, 250)

        self.setup_websocket = function () {
            if (!self.competition_id) return
            if (self.ws && (self.ws.readyState === WebSocket.OPEN || self.ws.readyState === WebSocket.CONNECTING)) {
                return
            }
            var ws_protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
            var ws_url = `${ws_protocol}//${window.location.host}/ws/leaderboard/${self.competition_id}/`
            var WSClass = window.ReconnectingWebSocket || window.WebSocket
            if (!WSClass) return

            if (window.ReconnectingWebSocket) {
                self.ws = new ReconnectingWebSocket(ws_url, null, {
                    automaticOpen: true,
                    maxReconnectAttempts: 10,
                    reconnectInterval: 1500
                })
            } else {
                self.ws = new WebSocket(ws_url)
            }

            self.ws.addEventListener("message", function (event) {
                try {
                    var data = JSON.parse(event.data)
                    if (data.type === 'leaderboard_update') {
                        if (!data.phase_id || data.phase_id == self.phase_id) {
                            self.debounced_update_leaderboard()
                        }
                    }
                } catch (err) {
                    console.error("Failed to parse leaderboard websocket event:", err)
                }
            })
        }

        self.close_websocket = function () {
            if (self.ws) {
                try {
                    self.ws.close()
                } catch (err) {}
                self.ws = null
            }
        }

        self.get_detailed_result_submisison_id = function(column, submisison){
            for (index in submisison.detailed_results) {
                if (column.task_id == submisison.detailed_results[index].task) {
                    return submisison.detailed_results[index].id
                }
            }
        }

        CODALAB.events.on('results_tab_visible', () => {
            self.is_tab_visible = true
            if (self.phase_id) {
                self.update_leaderboard()
            }
            self.setup_websocket()
        })

        CODALAB.events.on('results_tab_hidden', () => {
            self.is_tab_visible = false
            self.close_websocket()
        })

        CODALAB.events.on('phase_selected', data => {
            self.phase_id = data.id
            self.page = 1
            self.update_leaderboard()
        })

        CODALAB.events.on('competition_loaded', (competition) => {
            self.competition_id = competition.id
            self.participant_status = competition.participant_status
            self.opts.is_admin ? self.show_download = "visible" : self.show_download = "hidden"
            self.enable_detailed_results = competition.enable_detailed_results
            self.show_detailed_results_in_leaderboard = competition.show_detailed_results_in_leaderboard
            if (self.is_tab_visible) {
                self.setup_websocket()
                if (self.phase_id) {
                    self.update_leaderboard()
                }
            }
        })

        CODALAB.events.on('submission_changed_on_leaderboard', self.debounced_update_leaderboard)

        self.on('unmount', function () {
            self.close_websocket()
        })
    </script>
    
    <style type="text/stylus">
        :scope
            display: block
            width: 100%
            height: 100%
        .leaderboard-controls
            display flex
            align-items center
            flex-wrap wrap
            gap 12px
            margin-top 24px
            margin-bottom 16px
        .search-input
            width 33%
            min-width 240px
        .org-toggle-container
            display flex
            align-items center
            gap 8px
            margin-left auto
        .celled.table.selectable
            margin 1em 0
        table tbody .center.aligned td
            color #8c8c8c
        .index-column
            min-width 55px
        .leaderboard-title 
            position: absolute
            left: 50%
            transform: translate(-50%, -50%)
        .ui.table > thead > tr.task-row > th
            background-color: #e8f6ff !important
        .eye-icon-link
            position: relative
            display: block
        .eye-icon
            position: absolute
            top: 50%
            left: 50%
            transform: translate(-50%, -50%)
        .score-cell
            text-align center !important
            font-weight 600
        .text-bold
            font-weight: 600
        .raw-score
            display block
            font-weight normal
            font-size 0.8em
            line-height 1.3
            color rgba(0, 0, 0, 0.45)
            text-align center !important
            font-variant-numeric tabular-nums
            font-feature-settings 'tnum'
        .total-score-cell
            font-weight bold !important
            font-size 1.15em !important
            color #2185d0 !important
            text-align center !important
            font-variant-numeric tabular-nums
            font-feature-settings 'tnum'
        .final-score-header
            color #2185d0 !important
            font-weight bold !important
            text-align center !important
        .final-score-cell-col
            text-align center !important
        .card-org-subtext
            font-size 0.85em
            color rgba(0, 0, 0, 0.55)
            margin-top 2px

        /* Mobile Card Styling */
        .leaderboard-cards
            display none
            margin-top 16px
        .leaderboard-empty-cards
            display none
            padding 24px
            text-align center
            color #888
            background #fff
            border 1px solid #e0e0e0
            border-radius 8px
            margin-top 16px
        .leaderboard-card-header
            text-align center
            background #f8f9fa
            border 1px solid #e9ecef
            border-radius 6px
            padding 10px
            margin-bottom 14px
            h4
                margin 0
                color #2b3a4a
                font-weight 600
        .leaderboard-card
            background #fff
            border 1px solid #e0e0e0
            border-radius 8px
            box-shadow 0 2px 4px rgba(0, 0, 0, 0.04)
            margin-bottom 16px
            padding 14px 16px
            position relative
            transition box-shadow 0.2s ease
            &:hover
                box-shadow 0 4px 8px rgba(0, 0, 0, 0.08)
        .card-award-banner
            margin-bottom 8px
            display flex
            align-items center
        .card-plain-rank
            font-size 1.2em
            font-weight bold
            color #495057
            padding-left 4px
        .card-row
            display flex
            justify-content space-between
            align-items center
            padding 8px 0
            border-bottom 1px solid #f1f3f5
            &:last-child
                border-bottom none
        .card-label
            font-weight 600
            color #495057
            font-size 0.95em
            flex-shrink 0
            margin-right 12px
        .card-value
            text-align right
            font-size 0.95em
            color #212529
            word-break break-word
            .raw-score
                text-align right !important
        .participant-link
            font-weight 600
            color #2185d0
        .card-final-score-row
            background-color #f7fbff
            margin 4px -16px -14px -16px
            padding 12px 16px
            border-top 1px solid #d4e8fa
            border-bottom-left-radius 8px
            border-bottom-right-radius 8px
        .final-score-label
            color #1b6ca8
            font-size 1.05em
            font-weight 700
        .final-score-value
            .total-score-cell
                font-size 1.25em !important
                color #2185d0 !important

        @media (max-width: 768px)
            #leaderboardTable
                display none !important
            .leaderboard-cards
                display block
            .leaderboard-empty-cards
                display block
            .leaderboard-controls
                flex-direction column
                align-items stretch
            .search-input
                width 100% !important
            .org-toggle-container
                margin-left 0
                width 100%
            .pagination-container
                flex-direction column !important
                gap 12px
                align-items stretch !important
                & > div
                    justify-content center
    </style>
</leaderboards>