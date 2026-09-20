<award-badge>
    <div class="award-badge-container">
        <!-- Trophy -->
        <svg if="{ award_type === 'trophy' }" class="award-svg trophy-svg" viewBox="0 0 40 40" width="36" height="36" xmlns="http://www.w3.org/2000/svg">
            <path d="M 12 11 C 6 11 5 21 13 23" fill="none" stroke="#d99316" stroke-width="2.5" stroke-linecap="round"/>
            <path d="M 28 11 C 34 11 35 21 27 23" fill="none" stroke="#d99316" stroke-width="2.5" stroke-linecap="round"/>
            <path d="M 10 9 C 10 21 16 25 20 25 C 24 25 30 21 30 9 Z" fill="#ffca28" stroke="#d99316" stroke-width="1.2"/>
            <ellipse cx="20" cy="8.5" rx="10" ry="2" fill="#ffe082" stroke="#d99316" stroke-width="1"/>
            <path d="M 12 10.5 C 12 19 16 23 20 23 C 21.5 23 23 22 24.5 20.5 C 20 20 15 16 14 10.5 Z" fill="#ffe082" opacity="0.6"/>
            <path d="M 18 25 L 22 25 L 21.5 29 L 18.5 29 Z" fill="#e09714"/>
            <path d="M 16 29 L 24 29 L 25 31 L 15 31 Z" fill="#c47d0b"/>
            <rect x="13" y="31" width="14" height="4" rx="1" fill="#8d5400"/>
            <line x1="14" y1="32" x2="26" y2="32" stroke="#ffca28" stroke-width="0.8" opacity="0.7"/>
            <text x="20" y="18" text-anchor="middle" dominant-baseline="central" fill="#5c3800" font-family="'Segoe UI', Roboto, Helvetica, Arial, sans-serif" font-weight="900" font-size="11">{ rank_value }</text>
        </svg>

        <!-- Gold Medal with Red Ribbon -->
        <svg if="{ award_type === 'gold' }" class="award-svg gold-svg" viewBox="0 0 40 40" width="36" height="36" xmlns="http://www.w3.org/2000/svg">
            <polygon points="14,2 17,2 21,15 17,15" fill="#d32f2f"/>
            <polygon points="26,2 23,2 19,15 23,15" fill="#b71c1c"/>
            <rect x="18" y="13" width="4" height="3" rx="0.5" fill="#d4af37"/>
            <circle cx="20" cy="26" r="12" fill="#f5b027" stroke="#c4820e" stroke-width="1.2"/>
            <circle cx="20" cy="26" r="9.5" fill="#f8c352" stroke="#d69218" stroke-width="0.8"/>
            <text x="20" y="26" text-anchor="middle" dominant-baseline="central" fill="#6d4300" font-family="'Segoe UI', Roboto, Helvetica, Arial, sans-serif" font-weight="900" font-size="11">{ rank_value }</text>
        </svg>

        <!-- Silver Medal with Blue Ribbon -->
        <svg if="{ award_type === 'silver' }" class="award-svg silver-svg" viewBox="0 0 40 40" width="36" height="36" xmlns="http://www.w3.org/2000/svg">
            <polygon points="14,2 17,2 21,15 17,15" fill="#1976d2"/>
            <polygon points="26,2 23,2 19,15 23,15" fill="#1565c0"/>
            <rect x="18" y="13" width="4" height="3" rx="0.5" fill="#90a4ae"/>
            <circle cx="20" cy="26" r="12" fill="#cfd8dc" stroke="#90a4ae" stroke-width="1.2"/>
            <circle cx="20" cy="26" r="9.5" fill="#eceff1" stroke="#b0bec5" stroke-width="0.8"/>
            <text x="20" y="26" text-anchor="middle" dominant-baseline="central" fill="#37474f" font-family="'Segoe UI', Roboto, Helvetica, Arial, sans-serif" font-weight="900" font-size="11">{ rank_value }</text>
        </svg>

        <!-- Bronze Medal with Green Ribbon -->
        <svg if="{ award_type === 'bronze' }" class="award-svg bronze-svg" viewBox="0 0 40 40" width="36" height="36" xmlns="http://www.w3.org/2000/svg">
            <polygon points="14,2 17,2 21,15 17,15" fill="#388e3c"/>
            <polygon points="26,2 23,2 19,15 23,15" fill="#2e7d32"/>
            <rect x="18" y="13" width="4" height="3" rx="0.5" fill="#a16238"/>
            <circle cx="20" cy="26" r="12" fill="#cd7f32" stroke="#934f19" stroke-width="1.2"/>
            <circle cx="20" cy="26" r="9.5" fill="#dd944f" stroke="#b86b28" stroke-width="0.8"/>
            <text x="20" y="26" text-anchor="middle" dominant-baseline="central" fill="#4e2608" font-family="'Segoe UI', Roboto, Helvetica, Arial, sans-serif" font-weight="900" font-size="11">{ rank_value }</text>
        </svg>

        <!-- Plain number fallback -->
        <span if="{ !award_type && rank_value }" class="award-plain-rank">{ rank_value }</span>
    </div>

    <script>
        var self = this

        self.update_state = function () {
            var award = self.opts.award || {}
            self.award_type = self.opts.type || award.type || null
            self.rank_value = (self.opts.rank !== undefined && self.opts.rank !== null && self.opts.rank !== '')
                ? self.opts.rank
                : (award.rank !== undefined && award.rank !== null ? award.rank : '')
        }

        self.update_state()

        self.on('before-mount before-update update mount', function () {
            self.update_state()
        })
    </script>

    <style type="text/stylus">
        :scope
            display inline-block
            vertical-align middle
            text-align center
        .award-badge-container
            display inline-flex
            align-items center
            justify-content center
            width 36px
            height 36px
            max-width 36px
            max-height 36px
            overflow hidden
        .award-svg
            width 36px
            height 36px
            display block
            flex-shrink 0
        .award-plain-rank
            font-size 1.1em
            font-weight bold
            color #555
    </style>
</award-badge>
